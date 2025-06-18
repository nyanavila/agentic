# Use the latest OpenShift AI notebook base image
FROM quay.io/opendatahub/workbench-images:jupyter-datascience-ubi9-python-3.11-20250312-414a9c0

# Switch to root user to install dependencies
USER root

# Upgrade pip and install all dependencies from the single requirements file
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt && \
    # Get the site-packages path to locate the chromadb library
    PYTHON_SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])") && \
    # Inject the SQLite override into ChromaDB's __init__.py file
    # This is still useful if any library transitively depends on ChromaDB
    echo "__import__('pysqlite3'); import sys; sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')" > "$PYTHON_SITE_PACKAGES/chromadb/__init__.py.pre" && \
    cat "$PYTHON_SITE_PACKAGES/chromadb/__init__.py" >> "$PYTHON_SITE_PACKAGES/chromadb/__init__.py.pre" && \
    mv "$PYTHON_SITE_PACKAGES/chromadb/__init__.py.pre" "$PYTHON_SITE_PACKAGES/chromadb/__init__.py" && \
    # Set correct permissions for the OpenShift environment
    chmod -R g+w "$PYTHON_SITE_PACKAGES" && \
    fix-permissions "$PYTHON_SITE_PACKAGES"

# Copy utilities script into the image
COPY utils.py /opt/app-root/src/utils.py

# Switch back to OpenShift AI's default non-root user
USER 1001

# Set working directory (Must match OpenShift AI expectations)
WORKDIR /opt/app-root/src

# Expose Jupyter Notebook port
EXPOSE 8888

# Define the default entrypoint for the notebook
ENTRYPOINT ["start-notebook.sh"]
