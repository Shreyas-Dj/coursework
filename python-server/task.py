from celery import Celery
import time

#We're connecting celery to redis here
REDIS_URL = "redis://localhost:6379/0"

celery_app = Celery(
    "photogrammetry_tasks",
    broker=REDIS_URL,
    backend=REDIS_URL
)

#Labeling stages
@celery_app.task(bind=True)
def run_photogrammetry_pipeline(self, job_id: str, image_path: str):
    """Long task is running asynch in the background."""

    #Stage 1: SIFT
    self.update_state(
        state="PROCESSING",
        meta={"stage": "Detecting Features", "percent": 20, "message":"Just getting started with SIFT to find points"}
    )
    # execute_SIFT(image_paths)

    #Stage 2: Structure from motion (COLMAP) 
    self.update_state(
        state="PROCESSING",
        meta={"stage": "Reconstructing with SfM", "percent": 50, "message": "Estimating camera placement"}
    )
    #run_colmap_sfm(job_id)

    #Stage 3: Dense reconstruction using OpenMVS
    self.update_state(
        state="PROCESSING",
        meta={"stage": "Mesh creation", "percent": 80, "message": "Generating the dense point cloud and mesh"}
    )
    #run_openmvs(job_id)

    return {"stage": "Done", "percent": 100, "message": "Processing has been completed", "output_file": f"{job_id}.(required_file_format)"} #Fix this later with the user's requested file type

