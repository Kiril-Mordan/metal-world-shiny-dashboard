# Read the r_requirements.txt file
requirements <- readLines("env_spec/r_requirements.txt")

# Install the packages from the list
for (req in requirements) {
  install.packages(req, dependencies = TRUE)
}
