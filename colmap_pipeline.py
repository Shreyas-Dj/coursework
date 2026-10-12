import subprocess
import os
import logging

from config import settings

logger = logging.getLogger(__name__)


class ColmapError(Exception):
    """Raised when a COLMAP stage fails."""
    pass


def _run_command(stage_name: str, command: list[str]) -> None:
    """
    Run a COLMAP command via subprocess and raise ColmapError if it fails.
    (Basically running the thing that maps the mesh then tells me if something goes wrong)
    Logs stdout and stderr for debugging.
    """
    logger.info(f"[COLMAP] Starting stage: {stage_name}")
    logger.debug(f"[COLMAP] Command: {' '.join(command)}")

    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    if result.stdout:
        logger.debug(f"[COLMAP] stdout:\n{result.stdout}")
    if result.stderr:
        logger.debug(f"[COLMAP] stderr:\n{result.stderr}")

    if result.returncode != 0:
        raise ColmapError(
            f"Stage '{stage_name}' failed with exit code {result.returncode}.\n"
            f"stderr: {result.stderr.strip()}"
        )

    logger.info(f"[COLMAP] Stage completed: {stage_name}")


def _feature_extraction(database_path: str, image_path: str) -> None:
    """
    Stage 1: Detect keypoints and descriptors in every image.
    Results are stored in the SQLite database file.
    (Looking for interesting points and descriptions of parts of the image)
    """
    _run_command(
        "Feature Extraction",
        [
            "colmap", "feature_extractor",
            "--database_path", database_path,
            "--image_path", image_path,
            "--ImageReader.single_camera", str(int(settings.colmap_single_camera)),
            "--SiftExtraction.use_gpu", str(int(settings.colmap_use_gpu)),
        ],
    )


def _feature_matching(database_path: str) -> None:
    """
    Stage 2: Match keypoints across every pair of images.
    Exhaustive matching compares all pairs — suitable for small photo sets (<100 images).
    For larger sets, switch to sequential_matcher or vocab_tree_matcher.
    (Piecing images together)
    """
    _run_command(
        "Feature Matching",
        [
            "colmap", "exhaustive_matcher",
            "--database_path", database_path,
            "--SiftMatching.use_gpu", str(int(settings.colmap_use_gpu)),
        ],
    )


def _sparse_reconstruction(
    database_path: str,
    image_path: str,
    sparse_output_path: str,
) -> None:
    """
    Stage 3: Structure-from-Motion (SfM).
    Uses matched features to estimate camera poses and produce a sparse point cloud.
    Output is written to sparse_output_path as a COLMAP model (cameras.bin, images.bin, points3D.bin).
    (Figures out where the camera was and what the 3D points are in space)
    """
    os.makedirs(sparse_output_path, exist_ok=True)

    _run_command(
        "Sparse Reconstruction (SfM)",
        [
            "colmap", "mapper",
            "--database_path", database_path,
            "--image_path", image_path,
            "--output_path", sparse_output_path,
        ],
    )


def run_colmap(job_id: str, jobs: dict) -> str:
    """
    Run the full COLMAP SfM pipeline for a given job.

    Stages:
        1. Feature extraction - 33% progress
        2. Feature matching  - 66% progress
        3. Sparse reconstruction - 100% progress

    Args:
        job_id: The unique job identifier.
        jobs:   The shared in-memory jobs dictionary (updated with progress/status).

    Returns:
        The path to the sparse reconstruction output folder.

    Raises:
        ColmapError: If any COLMAP stage fails.
        FileNotFoundError: If the image folder for the job doesn't exist.
    """
    image_path = os.path.join(settings.upload_dir, job_id)
    database_path = os.path.join(image_path, "database.db")
    sparse_output_path = os.path.join(settings.sparse_dir, job_id)

    if not os.path.exists(image_path):
        raise FileNotFoundError(
            f"Image folder not found for job '{job_id}': {image_path}"
        )

    try:
        # --- Stage 1: Feature Extraction ---
        jobs[job_id]["status"] = "processing"
        jobs[job_id]["stage"] = "Feature Extraction"
        _feature_extraction(database_path, image_path)
        jobs[job_id]["progress"] = 33

        # --- Stage 2: Feature Matching ---
        jobs[job_id]["stage"] = "Feature Matching"
        _feature_matching(database_path)
        jobs[job_id]["progress"] = 66

        # --- Stage 3: Sparse Reconstruction ---
        jobs[job_id]["stage"] = "Sparse Reconstruction"
        _sparse_reconstruction(database_path, image_path, sparse_output_path)
        jobs[job_id]["progress"] = 100

        jobs[job_id]["stage"] = "Completed"
        logger.info(f"[COLMAP] Pipeline finished for job {job_id}")
        return sparse_output_path

    except ColmapError as e:
        jobs[job_id]["status"] = "failed"
        jobs[job_id]["error"] = str(e)
        logger.error(f"[COLMAP] Pipeline failed for job {job_id}: {e}")
        raise
