from fastapi import FastAPI, UploadFile, File, HTTPException, BackgroundTasks
import uuid
import os
import shutil
import asyncio # Only here to simulate processing time

app = FastAPI()

# Your original setup
UPLOAD_DIR = "uploads"
OUTPUT_DIR = "outputs"
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Tracks job statuses in memory
jobs = {}

# NEW: The background function that does the heavy lifting
async def process_mesh_background(job_id: str):
    jobs[job_id]["status"] = "processing"
    
    # Simulating a process that updates a progress bar
    for progress in [25, 50, 75, 100]:
        await asyncio.sleep(2) # Simulate work
        jobs[job_id]["progress"] = progress
        
    jobs[job_id]["status"] = "completed"

@app.post("/jobs")
async def create_job(
    project_name: str,
    output_format: str,
    mesh_density: str,
    background_tasks: BackgroundTasks, # NEW: Added to your parameters
    files: list[UploadFile] = File(...)
):
    # Your original ID and folder creation
    job_id = str(uuid.uuid4())
    job_folder = os.path.join(UPLOAD_DIR, job_id)
    os.makedirs(job_folder, exist_ok=True)
    
    # Your exact file saving logic
    saved_files = []
    for file in files:
        file_path = os.path.join(job_folder, file.filename)
        try:
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            saved_files.append(file.filename)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to save file {file.filename}: {str(e)}")
        finally:
            await file.close()

    # Your original dictionary update, just adding a "progress" key
    jobs[job_id] = {
        "project_name": project_name,
        "output_format": output_format,
        "mesh_density": mesh_density,
        "status": "queued",
        "progress": 0, # Added this to track the percentage
        "files": saved_files
    }
    
    # NEW: Send the heavy processing to the background
    background_tasks.add_task(process_mesh_background, job_id)
    
    # Your original return statement
    return {
        "message": "Job created successfully",
        "job_id": job_id,
        "status": jobs[job_id]["status"]
    }

# NEW: The endpoint for the mobile app to check the progress
@app.get("/jobs/{job_id}/status")
async def get_job_status(job_id: str):
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")
        
    return {
        "status": jobs[job_id]["status"],
        "progress": jobs[job_id]["progress"]
    }