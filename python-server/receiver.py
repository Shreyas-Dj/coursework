from fastapi import FastAPI, UploadFile, File, HTTPException, BackgroundTasks
from typing import Literal
import uuid
import os
import shutil
import asyncio

# Initialize the FastAPI application instance
app = FastAPI()

# Define directory paths for storing uploaded image files and generated 3D outputs
UPLOAD_DIR = "uploads"
OUTPUT_DIR = "outputs"

# Ensure the upload and output directories exist on startup to prevent FileNotFoundError
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Restrict uploaded files to standard image formats to prevent processing errors or security vulnerabilities
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/tiff"}

# NOTE: In-memory store — all job state is lost if the server restarts.
# Replace with a database (e.g. SQLite via SQLModel) for production.
# Dictionary acting as a temporary database to track job statuses, metadata, and progress
jobs: dict[str, dict] = {}


async def process_mesh_background(job_id: str):
    """Simulated heavy processing. Replace the loop body with your real mesh pipeline."""
    # Mark the job as currently processing so clients know it has started
    jobs[job_id]["status"] = "processing"

    # Simulate a long-running compute task by iterating through progress percentages and pausing
    for progress in [25, 50, 75, 100]:
        await asyncio.sleep(2)
        jobs[job_id]["progress"] = progress

    # Define the destination path where the final generated mesh would be saved
    output_path = os.path.join(OUTPUT_DIR, f"{job_id}.obj")
    
    # Update job state to reflect successful completion and store the final output file path
    jobs[job_id]["status"] = "completed"
    jobs[job_id]["output_file"] = output_path


@app.post("/jobs", status_code=201)
async def create_job(
    project_name: str,
    output_format: Literal["obj", "glb", "ply", "stl"],
    mesh_density: Literal["low", "medium", "high"],
    background_tasks: BackgroundTasks,
    files: list[UploadFile] = File(...),
):
    # Ensure the user has actually uploaded at least one file before proceeding
    if not files:
        raise HTTPException(status_code=422, detail="At least one image file is required.")

    # Validate file types before touching the filesystem
    # Iterates through the uploaded files and checks against the ALLOWED_IMAGE_TYPES set
    for file in files:
        if file.content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(
                status_code=415,
                detail=f"Unsupported file type '{file.content_type}' for '{file.filename}'. "
                       f"Allowed types: {', '.join(ALLOWED_IMAGE_TYPES)}",
            )

    # Generate a unique UUID to safely track the job and isolate its files
    job_id = str(uuid.uuid4())
    
    # Create a dedicated, isolated directory for this specific job's uploaded files
    job_folder = os.path.join(UPLOAD_DIR, job_id)
    os.makedirs(job_folder, exist_ok=True)

    saved_files = []
    # Save each validated file to the newly created job directory
    for file in files:
        file_path = os.path.join(job_folder, file.filename)
        try:
            # Open a file buffer to stream and write the uploaded binary data to the local disk
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            saved_files.append(file.filename)
        except Exception as e:
            # Catch any file writing errors (e.g., out of space, permissions) and return a 500 Internal Server Error
            raise HTTPException(
                status_code=500,
                detail=f"Failed to save file '{file.filename}': {str(e)}",
            )
        finally:
            # Ensure the uploaded file resource is closed properly to free system memory and file descriptors
            await file.close()

    # Populate the dict BEFORE scheduling the background task to avoid a
    # race condition where process_mesh_background runs before jobs[job_id] exists.
    # Initialize the job's tracking state in the in-memory store
    jobs[job_id] = {
        "project_name": project_name,
        "output_format": output_format,
        "mesh_density": mesh_density,
        "status": "queued",
        "progress": 0,
        "files": saved_files,
        "output_file": None,
    }

    # Hand off the heavy processing function to FastAPI's background tasks executor so the HTTP request can return immediately
    background_tasks.add_task(process_mesh_background, job_id)

    # Immediately return a success response with the job_id so the client can begin polling for status
    return {
        "message": "Job created successfully",
        "job_id": job_id,
        "status": jobs[job_id]["status"],
    }


@app.get("/jobs/{job_id}")
async def get_job(job_id: str):
    """Return all metadata for a job."""
    # Check if the requested job exists in our tracking dictionary to prevent KeyError
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found.")
    
    # Unpack and return the complete dictionary containing all job details (files, settings, status)
    return {"job_id": job_id, **jobs[job_id]}


@app.get("/jobs/{job_id}/status")
async def get_job_status(job_id: str):
    """Lightweight endpoint for polling progress from the mobile app."""
    # Verify the job exists before trying to access its status state
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found.")
    
    # Return only the essential fields needed to populate a progress bar or status indicator
    return {
        "status": jobs[job_id]["status"],
        "progress": jobs[job_id]["progress"],
    }


@app.delete("/jobs/{job_id}", status_code=200)
async def delete_job(job_id: str):
    """Cancel a queued job or clean up a completed one, removing uploaded files."""
    # Ensure the job actually exists before attempting to delete it
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found.")

    # Prevent deletion if the background task is currently modifying files to prevent corruption or crashes
    if jobs[job_id]["status"] == "processing":
        raise HTTPException(
            status_code=409,
            detail="Cannot delete a job that is currently processing.",
        )

    # Remove uploaded files from disk
    # Target the specific job directory containing the source files
    job_folder = os.path.join(UPLOAD_DIR, job_id)
    # If the folder exists, recursively delete it and all its contents
    if os.path.exists(job_folder):
        shutil.rmtree(job_folder)

    # Remove the job entry from the in-memory tracking dictionary
    del jobs[job_id]
    return {"message": f"Job {job_id} deleted successfully."}