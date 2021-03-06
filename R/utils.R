#' Converts a class vector (integers) to binary class matrix.
#' 
#' @details 
#' E.g. for use with [loss_categorical_crossentropy()].
#' 
#' @param y Class vector to be converted into a matrix (integers from 0 to num_classes).
#' @param num_classes Total number of classes.
#' 
#' @return A binary matrix representation of the input.
#' 
#' @export
to_categorical <- function(y, num_classes = NULL) {
  keras$utils$to_categorical(
    y = y,
    num_classes = as_nullable_integer(num_classes)
  )
}

 
#' Downloads a file from a URL if it not already in the cache.
#' 
#' Passing the MD5 hash will verify the file after download as well as if it is
#' already present in the cache.
#' 
#' @param fname Name of the file. If an absolute path `/path/to/file.txt` is 
#'   specified the file will be saved at that location.
#' @param origin Original URL of the file.
#' @param file_hash The expected hash string of the file after download. The
#'   sha256 and md5 hash algorithms are both supported.
#' @param cache_subdir Subdirectory under the Keras cache dir where the file is 
#'   saved. If an absolute path `/path/to/folder` is specified the file will be
#'   saved at that location.
#' @param hash_algorithm Select the hash algorithm to verify the file. options
#'   are 'md5', 'sha256', and 'auto'. The default 'auto' detects the hash
#'   algorithm in use.
#' @param extract True tries extracting the file as an Archive, like tar or zip.
#' @param archive_format Archive format to try for extracting the file. Options
#'   are 'auto', 'tar', 'zip', and None. 'tar' includes tar, tar.gz, and tar.bz
#'   files. The default 'auto' is ('tar', 'zip'). None or an empty list will
#'   return no matches found.
#' @param cache_dir Location to store cached files, when `NULL` it defaults to
#'   the Keras configuration directory.
#'   
#' @return Path to the downloaded file
#'   
#' @export
get_file <- function(fname, origin, file_hash = NULL, cache_subdir = "datasets", 
                     hash_algorithm = "auto", extract = FALSE,
                     archive_format = "auto", cache_dir = NULL) {
  keras$utils$get_file(
    fname = normalize_path(fname),
    origin = origin,
    file_hash = file_hash,
    cache_subdir = cache_subdir,
    hash_algorithm = hash_algorithm,
    extract = extract,
    archive_format = archive_format,
    cache_dir = normalize_path(cache_dir)
  )
}


#' Representation of HDF5 dataset to be used instead of an R array
#' 
#' @param datapath string, path to a HDF5 file
#' @param dataset string, name of the HDF5 dataset in the file specified in datapath
#' @param start int, start of desired slice of the specified dataset
#' @param end int, end of desired slice of the specified dataset
#' @param normalizer function to be called on data when retrieved
#' 
#' @return An array-like HDF5 dataset.
#' 
#' @details 
#' Providing `start` and `end` allows use of a slice of the dataset.
#' 
#' Optionally, a normalizer function (or lambda) can be given. This will
#' be called on every slice of data retrieved.
#' 
#' @export
hdf5_matrix <- function(datapath, dataset, start = 0, end = NULL, normalizer = NULL) {
  
  if (!have_h5py())
    stop("The h5py Python package is required to read h5 files")
  
  keras$utils$HDF5Matrix(
    datapath = normalize_path(datapath), 
    dataset = dataset,
    start = as.integer(start),
    end = as_nullable_integer(end),
    normalizer = normalizer
  )  
}

#' Normalize a matrix or nd-array
#' 
#' @param x Matrix or array to normalize
#' @param axis Axis along which to normalize
#' @param order Normalization order (e.g. 2 for L2 norm) 
#' 
#' @return A normalized copy of the array.
#' 
#' @export
normalize <- function(x, axis = -1, order = 2) {
  keras$utils$normalize(
    x = x,
    axis = as.integer(axis),
    order = as.integer(order)
  )
}


#' Keras array object
#'
#' Convert an R vector, matrix, or array object to an array that has the optimal
#' in-memory layout and floating point data type for the current Keras backend.
#'
#' Keras does frequent row-oriented access to arrays (for shuffling and drawing
#' batches) so the order of arrays created by this function is always
#' row-oriented ("C" as opposed to "Fortran" ordering, which is the default for
#' R arrays).
#'
#' If the passed array is already a NumPy array with the desired `dtype` and "C"
#' order then it is returned unmodified (no additional copies are made).
#'
#' @param x Object or list of objects to convert
#' @param dtype NumPy data type (e.g. float32, float64). If this is unspecified
#'   then R doubles will be converted to the default floating point type for the
#'   current Keras backend.
#'
#' @return NumPy array with the specified `dtype` (or list of NumPy arrays if a
#'   list was passed for `x`).
#'
#' @export
keras_array <- function(x, dtype = NULL) {
  
  # reflect NULL
  if (is.null(x))
    return(x)
  
  # recurse for lists
  if (is.list(x))
    return(lapply(x, keras_array))
  
  # convert to numpy
  if (!inherits(x, "numpy.ndarray")) {
    
    # establish the target datatype - if we are converting a double from R
    # into numpy then use the default floatx for the current backend
    if (is.null(dtype) && is.double(x))
      dtype <- backend()$floatx()
    
    # convert non-array to array
    if (!is.array(x))
      x <- as.array(x)
    
    # do the conversion (will result in Fortran column ordering)
    x <- r_to_py(x)
  }
  
  # if we don't yet have a dtype then use the converted type
  if (is.null(dtype))
    dtype <- x$dtype
  
  # ensure we use C column ordering (won't create a new array if the array
  # is already using C ordering)
  x$astype(dtype = dtype, order = "C", copy = FALSE)
}


#' Check if Keras is Available
#'
#' Probe to see whether the Keras python package is available in the current
#' system environment.
#'
#' @param version Minimum required version of Keras (defaults to `NULL`, no
#'   required version).
#'
#' @return Logical indicating whether Keras (or the specified minimum version of
#'   Keras) is available.
#'
#' @examples
#' \dontrun{
#' # testthat utilty for skipping tests when Keras isn't available
#' skip_if_no_keras <- function(version = NULL) {
#'   if (!is_keras_available(version))
#'     skip("Required keras version not available for testing")
#' }
#'
#' # use the function within a test
#' test_that("keras function works correctly", {
#'   skip_if_no_keras()
#'   # test code here
#' })
#' }
#'
#' @export
is_keras_available <- function(version = NULL) {
  implementation_module <- resolve_implementation_module()
  if (reticulate::py_module_available(implementation_module)) {
    if (!is.null(version))
      keras_version() >= version
    else
      TRUE
  } else {
    FALSE
  }
}


#' Keras implementation
#' 
#' Obtain a reference to the Python module used for the implementation of Keras.
#' 
#' There are currently two Python modules which implement Keras:
#' 
#' - keras ("keras")
#' - tensorflow.contrib.keras ("tensorflow")
#' 
#' This function returns a reference to the implementation being currently 
#' used by the keras package. The default implementation is "keras".
#' You can override this by setting the `KERAS_IMPLEMENTATION` environment
#' variable to "tensorflow".
#' 
#' @return Reference to the Python module used for the implementation of Keras.
#' 
#' @export
implementation <- function() {
  keras
}


#' Keras backend tensor engine
#' 
#' Obtain a reference to the `keras.backend` Python module used to implement
#' tensor operations.
#'
#' @inheritParams reticulate::import
#'
#' @note See the documentation here <https://keras.io/backend/> for 
#'   additional details on the available functions.
#'
#' @return Reference to Keras backend python module.
#'  
#' @export   
backend <- function(convert = TRUE) {
  if (convert)
    keras$backend
  else
    r_to_py(keras$backend)
}


is_backend <- function(name) {
  identical(backend()$backend(), name)
}

is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

is_osx <- function() {
  Sys.info()["sysname"] == "Darwin"
}

relative_to <- function(dir, file) {
  
  # normalize paths
  dir <- normalizePath(dir, mustWork = FALSE, winslash = "/")
  file <- normalizePath(file, mustWork = FALSE, winslash = "/")
  
  # ensure directory ends with a /
  if (!identical(substr(dir, nchar(dir), nchar(dir)), "/")) {
    dir <- paste(dir, "/", sep="")
  }
  
  # if the file is prefixed with the directory, return a relative path
  if (identical(substr(file, 1, nchar(dir)), dir))
    file <- substr(file, nchar(dir) + 1, nchar(file))
  
  # simplify ./
  if (identical(substr(file, 1, 2), "./"))
    file <- substr(file, 3, nchar(file))
  
  file
}


