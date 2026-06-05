from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import uuid
import os
import shutil

app = FastAPI()

# Where uploaded images and completed meshes get stored
UPLOAD_DIR = "uploads"
OUTPUT_DIR = "outputs"
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Tracks job statuses in memory (later you would use a database)
jobs = {}

@app.post("/jobs")
async def create_job(
    project_name: str,
    output_format: str,
    mesh_density: str,
    files: list[UploadFile] = File(...)


):
    #Making a unique id for this job
    job_id = str(uuid.uuid4())
    job_folder = os.path.join(UPLOAD_DIR, job_id)
    os.makedirs(job_folder, exist_ok=True)
    
    #Save the uploaded files to the job folder
    saved_files = []
    for file in files:
        # Secure the filename or use the original one
        file_path = os.path.join(job_folder, file.filename)
        
        # Read the uploaded file chunks and write them to disk
        try:
            with open(file_path, "wb") as buffer:
                # shutil.copyfileobj is efficient for copying file streams
                shutil.copyfileobj(file.file, buffer)
            saved_files.append(file.filename)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to save file {file.filename}: {str(e)}")
        finally:
            await file.close() # Always close the UploadFile stream to free memory

    #Track the job status in memory
    jobs[job_id] = {
        "project_name": project_name,
        "output_format": output_format,
        "mesh_density": mesh_density,
        "status": "pending",
        "files": saved_files
    }
    
    #Return the job ID to the mobile client
    return {
        "message": "Job created successfully",
        "job_id": job_id,
        "status": jobs[job_id]["status"]
    }
    