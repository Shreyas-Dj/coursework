# Imports
from fastapi import FastAPI, UploadFile, File, HTTPException, BackgroundTasks
from typing import Literal
import uuid
import os
import shutil
import asyncio

from config import settings
from colmap_pipeline import run_colmap, ColmapError

app = FastAPI()

# Making folders
os.makedirs(settings.upload_dir, exist_ok=True)
os.makedirs(settings.output_dir, exist_ok=True)

# NOTE: In-memory store — all job state is lost if the server restarts.
# Replace with a database once finished.
jobs: dict[str, dict] = {}


async def process_mesh_background(job_id: str):
    try:
        sparse_path = await asyncio.to_thread(run_colmap, job_id, jobs)
        jobs[job_id]["status"] = "completed"
        jobs[job_id]["sparse_output"] = sparse_path
    except (ColmapError, FileNotFoundError):
        pass  # run_colmap already sets jobs[job_id]["status"] = "failed"


@app.post("/jobs", status_code=201)
# Create a new reconstruction job and state options
async def create_job(
    project_name: str,
    output_format: Literal["obj", "glb", "ply", "stl"],
    mesh_density: Literal["low", "medium", "high"],
    background_tasks: BackgroundTasks,
    files: list[UploadFile] = File(...),
):
    # Validate image count against preset values in settings
    if len(files) < settings.min_images:
        raise HTTPException(
            status_code=422,
            detail=f"At least {settings.min_images} images are required for reconstruction. "
                   f"Got {len(files)}.",
        )
    # If there are too many images, give an error
    if len(files) > settings.max_images:
        raise HTTPException(
            status_code=422,
            detail=f"Too many images. Maximum allowed is {settings.max_images}. "
                   f"Got {len(files)}.",
        )

    # Validate file types against settings
    for file in files:
        if file.content_type not in settings.allowed_image_types:
            raise HTTPException(
                status_code=415,
                detail=f"Unsupported file type '{file.content_type}' for '{file.filename}'. "
                       f"Allowed types: {', '.join(settings.allowed_image_types)}",
            )

    # Create a unique job ID and folder for the uploads
    job_id = str(uuid.uuid4())
    job_folder = os.path.join(settings.upload_dir, job_id)
    os.makedirs(job_folder, exist_ok=True)

    saved_files = []
    for file in files:
        file_path = os.path.join(job_folder, file.filename)
        try:
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            saved_files.append(file.filename)
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to save file '{file.filename}': {str(e)}",
            )
        finally:
            await file.close()

    # Populate dict BEFORE scheduling background task to avoid a race condition
    jobs[job_id] = {
        "project_name": project_name,
        "output_format": output_format,
        "mesh_density": mesh_density,
        "status": "queued",
        "progress": 0,
        "stage": "Queued",
        "files": saved_files,
        "output_file": None,
    }

    background_tasks.add_task(process_mesh_background, job_id)

    return {
        "message": "Job created successfully",
        "job_id": job_id,
        "status": jobs[job_id]["status"],
    }

# Get job details
@app.get("/jobs/{job_id}")
async def get_job(job_id: str):
    """Return all metadata for a job."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found.")
    return {"job_id": job_id, **jobs[job_id]}


# Get job status
@app.get("/jobs/{job_id}/status")
async def get_job_status(job_id: str):
    """Lightweight endpoint for polling progress from the mobile app."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found.")
    return {
        "status": jobs[job_id]["status"],
        "progress": jobs[job_id]["progress"],
        "stage": jobs[job_id]["stage"],
    }


# Delete job
@app.delete("/jobs/{job_id}", status_code=200)
async def delete_job(job_id: str):
    """Cancel a queued job or clean up a completed one, removing uploaded files."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found.")

    if jobs[job_id]["status"] == "processing":
        raise HTTPException(
            status_code=409,
            detail="Cannot delete a job that is currently processing.",
        )

    job_folder = os.path.join(settings.upload_dir, job_id)
    if os.path.exists(job_folder):
        shutil.rmtree(job_folder)

    del jobs[job_id]
    return {"message": f"Job {job_id} deleted successfully."}
