#############################################################################
#Title:    FAVORaGDSToText
#Function:
# * Extract variants and functional annotation from an aGDS file.
# * Export the results into a tab-delimited text table.
#Author:   Hufeng Zhou
#############################################################################

args <- commandArgs(TRUE)

if(length(args) < 2)
{
  stop("Usage: Rscript FAVORaGDSToText.R input.agds AnnotationTextTable.tsv [annotation_node]")
}

gds.file <- args[1]
print(paste0("gds.file:  ",gds.file))

out.file <- args[2]
print(paste0("out.file:  ",out.file))

anno.node <- NA
if(length(args) >= 3)
{
  anno.node <- args[3]
  print(paste0("annotation node:  ",anno.node))
}

library(gdsfmt)
library(SeqArray)

#############################################################################
# Helper functions
#############################################################################

get_node <- function(genofile, node.path)
{
  tryCatch(
    index.gdsn(genofile, node.path),
    error = function(e) NULL
  )
}

read_node <- function(node)
{
  tryCatch(
    read.gdsn(node),
    error = function(e) NULL
  )
}

node_to_data_frame <- function(value, node.name)
{
  if(is.null(value))
  {
    return(NULL)
  }

  if(is.data.frame(value))
  {
    out <- value
  }else if(is.matrix(value))
  {
    out <- as.data.frame(value, stringsAsFactors = FALSE)
  }else if(is.list(value))
  {
    out <- tryCatch(
      as.data.frame(value, stringsAsFactors = FALSE, optional = TRUE),
      error = function(e) NULL
    )
  }else if(is.atomic(value))
  {
    out <- data.frame(value, stringsAsFactors = FALSE)
    names(out) <- node.name
  }else
  {
    out <- NULL
  }

  if(is.null(out))
  {
    return(NULL)
  }

  out <- as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
  names(out) <- make.unique(ifelse(names(out) == "", node.name, names(out)))
  out
}

normalize_annotation_node <- function(anno.node)
{
  anno.node <- gsub("^/+", "", anno.node)
  anno.node <- sub("^annotation/info/", "", anno.node)
  anno.node
}

candidate_annotation_nodes <- function(anno.root, anno.node)
{
  if(!is.na(anno.node))
  {
    return(normalize_annotation_node(anno.node))
  }

  known.nodes <- c(
    "FunctionalAnnotation",
    "FunctionalAnnotation/FunctionalAnnotation",
    "FunctionalAnnotation/FAVORannotator",
    "FunctionalAnnotationJun1st2022",
    "FAVORFullDB",
    "FAVORFullDBAug1st2022",
    "NewAnnotation"
  )

  all.nodes <- tryCatch(
    ls.gdsn(anno.root, recursive = TRUE, include.dirs = TRUE),
    error = function(e) character(0)
  )

  unique(c(known.nodes, all.nodes))
}

is_descendant_of_selected <- function(node.path, selected.paths)
{
  if(length(selected.paths) == 0)
  {
    return(FALSE)
  }

  any(vapply(
    selected.paths,
    function(selected.path)
    {
      startsWith(node.path, paste0(selected.path, "/"))
    },
    logical(1)
  ))
}

read_annotation_tables <- function(genofile, variant_info, anno.node)
{
  anno.root <- get_node(genofile, "annotation/info")
  if(is.null(anno.root))
  {
    stop("Could not find annotation/info in the input aGDS file.")
  }

  node.paths <- candidate_annotation_nodes(anno.root, anno.node)
  node.paths <- node.paths[node.paths != ""]
  node.paths <- node.paths[order(lengths(strsplit(node.paths, "/", fixed = TRUE)))]

  anno.tables <- list()
  selected.paths <- character(0)

  for(node.path in node.paths)
  {
    if(is_descendant_of_selected(node.path, selected.paths))
    {
      next
    }

    full.path <- paste0("annotation/info/", node.path)
    node <- get_node(genofile, full.path)
    if(is.null(node))
    {
      next
    }

    anno <- node_to_data_frame(read_node(node), basename(node.path))
    if(is.null(anno))
    {
      next
    }

    if(nrow(anno) == nrow(variant_info))
    {
      anno.tables[[node.path]] <- anno
      selected.paths <- c(selected.paths, node.path)
      next
    }

    if("variant_vcf" %in% names(anno))
    {
      idx <- match(variant_info$variant_vcf, anno$variant_vcf)
      anno <- anno[idx, , drop = FALSE]
      anno.tables[[node.path]] <- anno
      selected.paths <- c(selected.paths, node.path)
    }
  }

  if(length(anno.tables) == 0)
  {
    stop("No readable functional annotation table was found under annotation/info.")
  }

  anno.tables
}

remove_duplicate_variant_columns <- function(anno, variant_info)
{
  duplicate.columns <- intersect(names(anno), names(variant_info))
  anno[, setdiff(names(anno), duplicate.columns), drop = FALSE]
}

#############################################################################
# Extract variants and functional annotations
#############################################################################

genofile <- seqOpen(gds.file)
on.exit(seqClose(genofile))

CHR <- as.character(seqGetData(genofile, "chromosome"))
position <- as.integer(seqGetData(genofile, "position"))
REF <- as.character(seqGetData(genofile, "$ref"))
ALT <- as.character(seqGetData(genofile, "$alt"))

variant_info <- data.frame(
  variant_vcf = paste0(CHR,"-",position,"-",REF,"-",ALT),
  chromosome = CHR,
  position = position,
  ref_vcf = REF,
  alt_vcf = ALT,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

anno.tables <- read_annotation_tables(genofile, variant_info, anno.node)
anno.tables <- lapply(anno.tables, remove_duplicate_variant_columns, variant_info = variant_info)

annotation_table <- do.call(cbind, anno.tables)
output_table <- cbind(variant_info, annotation_table)
names(output_table) <- make.unique(names(output_table))

write.table(
  output_table,
  file = out.file,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = ""
)

print(paste0("Number of variants:  ",nrow(output_table)))
print(paste0("Number of columns:  ",ncol(output_table)))
print("Finished exporting aGDS annotation to text table.")
