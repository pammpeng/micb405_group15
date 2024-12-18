---
title: "MICB_405_final_project_group_15"
output:
  html_document:
    df_print: paged
---
Required libraries 
```{r Differential Gene Expression Analysis Required libraries}
library(Rsubread)
library(data.table)
library(DESeq2)
```
```{r Data Visualization Required libraries}
library(ggfortify)
library(ggplot2)
library(pheatmap)
library(VennDiagram)
```
```{r Pathway Analysis Required Libraries}
library(enrichR)
library(readxl)
library(ggplot2)
library(enrichplot)
library(cowplot)
```

Comparison 1: Transgenerational Comparison - reference to P0
```{r Metadata table generation}
# Define metadata information
transgenerational_sample_ids <- c("F1_1", "F1_2", "F1_3", "F1_4", "F1_5", "F3_1", "F3_2", "P0_1", "P0_2", "P0_3")
transgenerational_condition <- c("F1", "F1", "F1", "F1", "F1", "F3", "F3", "P0", "P0", "P0")
transgenerational_replicate <- c(1, 2, 3, 4, 5, 1, 2, 1, 2, 3)
# Compile into data frame
transgenerational_metadata <- data.frame(SampleID = transgenerational_sample_ids, Condition = transgenerational_condition, Replicate = transgenerational_replicate)
```
```{r Differential gene expression analysis in DESeq2}
# Import count matrix file
transgenerational_count_matrix <- read.table("/volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_final_count_matrix.txt", header = TRUE, row.names = 1, sep = "\t")
# Set P0 as the reference level & design formula
transgenerational_metadata$Condition <- as.factor(transgenerational_metadata$Condition)
transgenerational_metadata$Condition <- relevel(transgenerational_metadata$Condition, ref = "P0")
design <- ~ Condition
# Build dataset object (dds) & complete DEG analysis
transgenerational_dds <- DESeqDataSetFromMatrix(countData = transgenerational_count_matrix, colData = transgenerational_metadata, design = design)
transgenerational_DESeq <- DESeq(transgenerational_dds)
# Extract results & statistically significant DEGs
transgenerational_DESeq_results <- results(transgenerational_DESeq)
transgenerational_DESeq_results <- as.data.frame(transgenerational_DESeq_results)
transgenerational_DESeq_results <- transgenerational_DESeq_results[!is.na(transgenerational_DESeq_results$padj), ]
transgenerational_DEGs <- rownames(transgenerational_DESeq_results)
transgenerational_DESeq_results$Gene <- transgenerational_DEGs
write.csv(transgenerational_DESeq_results, file = "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_DESeq2_results.csv", row.names = FALSE)
```
Visualization of Differential Gene Expression Analysis
```{r PCA plot - clustering of samples based on similarity in differentially expressed genes}
# Perform variance stabilizing transformation (VST) on dds
transgenerational_dds <- vst(transgenerational_dds)
# Perform principal component analysis & convert results into data frame
transgenerational_pca <- prcomp(t(assay(transgenerational_dds)))
transgenerational_pca_df <- as.data.frame(transgenerational_pca$x)
# Define condition colours for the PCA plot
transgenerational_pca_df$Condition <- factor(transgenerational_metadata$Condition)
# Create PCA plot using ggofortify package
transgenerational_pca_plot <- autoplot(transgenerational_pca, data = transgenerational_pca_df) + geom_point(aes(color = Condition), size = 4) + geom_text(aes(label = transgenerational_sample_ids), vjust = 1.5, hjust = 0, size = 2.5) + labs(color = "Condition") + theme(panel.grid = element_blank(), panel.background = element_rect(fill = "white"), axis.line = element_line(color = "black"),axis.title.x = element_text(size = 14), axis.title.y = element_text(size = 14)) 
# Display the PCA & save to a file
print(transgenerational_pca_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_PCA_plot.png", plot = transgenerational_pca_plot, width = 6, height = 4, dpi = 500)
```
```{r Heatmap - similarity in magnitude of normalized gene counts}
# Subset count matrix to include significant differentially expressed genes
transgenerational_significant_DEGs <- rownames(transgenerational_DESeq_results)[which(transgenerational_DESeq_results$padj < 0.05)]  
transgenerational_statistically_significant_count_matrix <- transgenerational_count_matrix[transgenerational_significant_DEGs, ]
# Calculate Z-scores
transgenerational_z_scores <- t(scale(t(transgenerational_statistically_significant_count_matrix)))
# Create heatmap plot using Pheatmap package
transgenerational_heatmap <- pheatmap(transgenerational_z_scores, cluster_rows = TRUE, cluster_cols = FALSE, scale = "none", main = "Heatmap of Differentially Expressed Genes", fontsize = 8, show_row_dendrogram = FALSE, show_col_dendrogram = FALSE)
# Display plot & save into a file
print(transgenerational_heatmap)
ggsave("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_heatmap.png", plot = transgenerational_heatmap, width = 6, height = 4, dpi = 500)
```
Gene Set Enrichment Analysis (GSEA) - determine functionality of differentially expressed genes
```{r Venn Diagram of shared & uniquely expressed genes}
# Based on the workflow of this analysis, it is easier to re-run the DESeq during this step due to data transformation required
# Import count matrix file
transgenerational_count_matrix <- read.table("/volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_final_count_matrix.txt", header = TRUE, row.names = 1, sep = "\t")
# Set P0 as the reference level & design formula
transgenerational_metadata$Condition <- as.factor(transgenerational_metadata$Condition)
transgenerational_metadata$Condition <- relevel(transgenerational_metadata$Condition, ref = "P0")
design <- ~ Condition
# Build dataset object (dds) & complete DEG analysis
transgenerational_dds <- DESeqDataSetFromMatrix(countData = transgenerational_count_matrix, colData = transgenerational_metadata, design = design)
transgenerational_DESeq <- DESeq(transgenerational_dds)
# Extract statistically significant DEGs for each condition comparison
  # F1 DEGs, relative to P0
  transgenerational_F1_results <- results(transgenerational_DESeq, contrast=c("Condition", "F1", "P0"))
  transgenerational_F1_results <- subset(transgenerational_F1_results, padj < 0.05 & abs(log2FoldChange) > 1)
  transgenerational_F1_DEGs <- rownames(transgenerational_F1_results)
  transgenerational_F1_results$Gene <- transgenerational_F1_DEGs
  write.csv(transgenerational_F1_results, file = "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_F1_results.csv", row.names = FALSE)
  # F3 DEGs, relative to P0
  transgenerational_F3_results <- results(transgenerational_DESeq, contrast=c("Condition", "F3", "P0"))
  transgenerational_F3_results <- subset(transgenerational_F3_results, padj < 0.05 & abs(log2FoldChange) > 1)
  transgenerational_F3_DEGs <- rownames(transgenerational_F3_results)
  transgenerational_F3_results$Gene <- transgenerational_F3_DEGs
  write.csv(transgenerational_F3_results, file = "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_F3_results.csv", row.names = FALSE)
# Extract gene identifiers of significant DEGs
transgenerational_gene_lists <- list(Condition1 = transgenerational_F1_DEGs, Condition2 = transgenerational_F3_DEGs)
# Create Venn diagram using VennDiagram package
transgenerational_venn_diagram <- venn.diagram(x = transgenerational_gene_lists, category.names = c("F1", "F3"), scaled = FALSE, filename = NULL,cat.pos = 0, cat.dist = 0.04, cat.cex = 1.8, fill = c("lightgreen", "lightblue"), cex.prop = 8, cex = 1.5)
# Save the Venn diagram as a PDF
pdf("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_venn_diagram.pdf", width = 6, height = 4)  
grid.draw(transgenerational_venn_diagram)
dev.off()
```
```{r Enrichment Analysis Annotated to Gene Ontology}
# WormBase Gene ID was identfied using DAVID Gene ID conversion from RefSeq RNA 
GO_databases <- c("GO_Biological_Process_2018")
# Upregulated Genes in F1 generation
transgenerational_F1_up_genes <- read.csv("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/F1_upregulated_genes.csv")
transgenerational_F1_up_GO <- enrichr(transgenerational_F1_up_genes$Gene, GO_databases)
write.csv(transgenerational_F1_up_GO, "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/F1_upregulated_GO.csv", row.names = FALSE)
# Downregulated Genes in F1 generation
transgenerational_F1_down_genes <- read.csv("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/F1_downregulated_genes.csv")
transgenerational_F1_down_GO <- enrichr(transgenerational_F1_down_genes$Gene, GO_databases)
write.csv(transgenerational_F1_down_GO, "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/F1_downregulated_GO.csv", row.names = FALSE)
```
```{r GO motif analysis & visualization of genes unique to F1 generation}
# Upregulated pathways in F1
# Extract top 10 GO terms
transgenerational_F1_up_GO_terms <- transgenerational_F1_up_GO_terms[order(transgenerational_F1_up_GO$LogP), ][1:10, ]
# Plot top 10 GO terms using ggplot2 package
transgenerational_F1_up_GO_plot <- ggplot(transgenerational_F1_up_GO_terms , aes(x = reorder(Description, LogP), y = -LogP)) + geom_bar(stat = "identity", fill = "blue") + labs(title = "F1 Upregulated GO Biological Processes", x = NULL, y = "-Log10 (P-value)") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 8)) + coord_flip()
print(transgenerational_F1_up_GO_plot)
ggsave(transgenerational_F1_up_GO_plot, file = "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_F1_upregulated_GO_plot.png", width = 6, height = 4, dpi = 500)
# Downregulated pathways in F1 
# Extract top 10 GO terms
transgenerational_F1_down_GO_terms <- transgenerational_F1_down_GO_terms[order(transgenerational_F1_down_GO$LogP), ][1:10, ]
# Plot top 10 GO terms using ggplot2 package
transgenerational_F1_down_GO_plot <- ggplot(transgenerational_F1_down_GO_terms , aes(x = reorder(Description, LogP), y = -LogP)) + geom_bar(stat = "identity", fill = "blue") + labs(title = "F1 Downregulated GO Biological Processes", x = NULL, y = "-Log10 (P-value)") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 8)) + coord_flip() 
print(transgenerational_F1_down_GO_plot)
ggsave(transgenerational_F1_down_GO_plot, file = "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_F1_downregulated_GO_plot.png", width = 6, height = 4, dpi = 500)
```
```{r GO motif analysis of shared genes}
# Shared upregulated pathways
# Extract top 10 GO terms
transgenerational_shared_up_GO_terms <- transgenerational_shared_up_GO_terms[order(transgenerational_shared_up_GO$LogP), ][1:10, ]
# Plot top 10 GO terms using ggplot2 package
transgenerational_shared_up_GO_plot <- ggplot(transgenerational_shared_up_GO_terms , aes(x = reorder(Description, LogP), y = -LogP)) + geom_bar(stat = "identity", fill = "blue") + labs(title = "Shared Upregulated GO Biological Processes", x = NULL, y = "-Log10 (P-value)") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 8)) + coord_flip() 
print(transgenerational_shared_up_GO_plot)
ggsave(transgenerational_shared_up_GO_plot, file = "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_shared_upregulated_GO_plot.png", width = 76 height = 4, dpi = 500)
# Shared downregulated pathways 
# Extract top 10 GO terms
transgenerational_shared_down_GO_terms <- transgenerational_shared_down_GO_terms[order(transgenerational_shared_down_GO$LogP), ][1:10, ]
# Plot top 10 GO terms using ggplot2 package
transgenerational_shared_down_GO_plot <- ggplot(transgenerational_shared_down_GO_terms , aes(x = reorder(Description, LogP), y = -LogP)) + geom_bar(stat = "identity", fill = "blue") + labs(title = "Shared Downregulated GO Biological Processes", x = NULL, y = "-Log10 (P-value)") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 8)) + coord_flip() 
print(transgenerational_shared_down_GO_plot)
ggsave(transgenerational_shared_down_GO_plot, file = "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_shared_downregulated_GO_plot.png", width = 6, height = 4, dpi = 500)
```
```{r Enrichment Analysis Annotated to KEGG}
KEGG_databases <- c("KEGG")
# Upregulated Genes in F1 generation
transgenerational_F1_up_KEGG <- enrichr(F1_upregulated_genes$Gene, KEGG_databases)
write.csv(transgenerational_F1_up_KEGG, "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/F1_upregulated_KEGG.csv", row.names = FALSE)
# Downregulated Genes in F1 generation
transgenerational_F1_down_KEGG <- enrichr(F1_downregulated_genes$Gene, KEGG_databases)
write.csv(transgenerational_F1_down_KEGG, "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/F1_downregulated_KEGG.csv", row.names = FALSE)
# Upregulated Genes shared between F1 & F3 generations
transgenerational_shared_up_genes <- read.csv("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/shared_upregulated_genes.csv")
shared_up_KEGG_enrichment <- enrichr(transgenerational_shared_up_genes$Gene, KEGG_databases)
write.csv(shared_up_KEGG_enrichment, "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/shared_upregulated_KEGG.csv", row.names = FALSE)
# Downregulated Genes shared between F1 & F3 generations
transgenerational_shared_down_genes <- read.csv("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/shared_downregulated_genes.csv")
transgenerational_shared_down_KEGG <- enrichr(transgenerational_shared_down_genes$Gene, KEGG_databases)
write.csv(transgenerational_shared_down_KEGG, "/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/shared_downregulated_KEGG.csv", row.names = FALSE)
```
```{r KEGG dotplot - Pathways unique to F1 generation}
# Upregulated pathways in F1 generatoin
# Extract relevant information from EnrichR output
transgenerational_F1_up_pathways <- transgenerational_F1_up_KEGG$Term
transgenerational_F1_up_enrichment_scores <- transgenerational_F1_up_KEGG$Enrichment_score
transgenerational_F1_up_p_adjusted <- transgenerational_F1_up_KEGG$P_adjusted
transgenerational_F1_up_overlap <- transgenerational_F1_up_KEGG$Overlap
# Create dot plot using ggplot2
transgenerational_F1_up_KEGG_plot <- ggplot(transgenerational_F1_up_KEGG, aes(x = transgenerational_F1_up_enrichment_scores, y = transgenerational_F1_up_pathways, color = transgenerational_F1_up_p_adjusted, size = transgenerational_F1_up_overlap)) +  geom_point() + geom_segment(aes(x = 0, xend = transgenerational_F1_up_enrichment_scores, y = transgenerational_F1_up_pathways, yend = transgenerational_F1_up_pathways, color = transgenerational_F1_up_p_adjusted), size = 1, alpha = 0.5) +labs(title = "F1 Upregulated KEGG Pathways", x = "Enrichment Score", y = "Terms") + scale_color_continuous(name = "P-value", low = "blue", high = "red") + theme_minimal() +  theme(axis.text.y = element_text(size = 8), axis.title.y = element_text(size = 8))
print(transgenerational_F1_up_KEGG_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_F1_upregulated_KEGG_plot.png", plot = transgenerational_F1_up_KEGG_plot, width = 6, height = 4, dpi = 500)
# Downregulated KEGG patwhays in F1 generation
# Extract relevant information from EnrichR output
transgenerational_F1_down_pathways <- transgenerational_F1_down_KEGG$Term
transgenerational_F1_down_enrichment_scores <- transgenerational_F1_down_KEGG$Enrichment_score
transgenerational_F1_down_p_adjusted <- transgenerational_F1_down_KEGG$P_adjusted
transgenerational_F1_down_overlap <- transgenerational_F1_down_KEGG$Overlap
# Create dot plots for each dataset
transgenerational_F1_down_KEGG_plot <- ggplot(transgenerational_F1_down_KEGG, aes(x = transgenerational_F1_down_enrichment_scores, y = transgenerational_F1_down_pathways, color = transgenerational_F1_down_p_adjusted, size = transgenerational_F1_down_overlap)) +  geom_point() + geom_segment(aes(x = 0, xend = transgenerational_F1_down_enrichment_scores, y = transgenerational_F1_down_pathways, yend = transgenerational_F1_down_pathways, color = transgenerational_F1_down_p_adjusted), size = 1, alpha = 0.5) + labs(title = "F1 Downregulated KEGG Pathways", x = "Enrichment Score", y = "Terms") + scale_color_continuous(name = "P-value", low = "blue", high = "red") + theme_minimal() +  theme(axis.text.y = element_text(size = 8), axis.title.y = element_text(size = 8))
print(transgenerational_F1_down_KEGG_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/transgenerational_F1_downregulated_KEGG_plot.png", plot = transgenerational_F1_down_KEGG_plot, width = 6, height = 4, dpi = 500)
```
```{r KEGG dotplot - shared pathways}
# Upregulated shared pathways
# Extract relevant information from EnrichR output
transgenerational_shared_up_pathways <- transgenerational_shared_up_KEGG$Term
transgenerational_shared_up_enrichment_scores <- transgenerational_shared_up_KEGG$Enrichment_score
transgenerational_shared_up_p_adjusted <- transgenerational_shared_up_KEGG$P_adjusted
transgenerational_shared_up_overlap <- transgenerational_shared_up_KEGG$Overlap
# Create dot plots for each dataset
transgenerational_shared_up_KEGG_plot <- ggplot(transgenerational_shared_up_KEGG, aes(x = transgenerational_shared_up_enrichment_scores, y = transgenerational_shared_up_pathways, color = transgenerational_shared_up_p_adjusted, size = transgenerational_shared_up_overlap)) +  geom_point() + geom_segment(aes(x = 0, xend = transgenerational_shared_up_enrichment_scores, y = transgenerational_shared_up_pathways, yend = transgenerational_shared_up_pathways, color = transgenerational_shared_up_p_adjusted), size = 1, alpha = 0.5) + labs(title = "Shared Upregulated KEGG Pathways", x = "Enrichment Score", y = "Terms") + scale_color_continuous(name = "P-value", low = "blue", high = "red") + theme_minimal() +  theme(axis.text.y = element_text(size = 8), axis.title.y = element_text(size = 8))
print(transgenerational_shared_up_KEGG_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/shared_upregulated_KEGG_plot.png", plot = transgenerational_shared_up_KEGG_plot, width = 6, height = 4, dpi = 500)
# Downregulated shared pathways
# Extract relevant information from EnrichR output
transgenerational_shared_down_pathways <- transgenerational_shared_down_KEGG$Term
transgenerational_shared_down_enrichment_scores <- transgenerational_shared_down_KEGG$Enrichment_score
transgenerational_shared_down_p_adjusted <- transgenerational_shared_down_KEGG$P_adjusted
transgenerational_shared_down_overlap <- transgenerational_shared_down_KEGG$Overlap
# Create dot plots for each dataset
transgenerational_shared_down_KEGG_plot <- ggplot(transgenerational_shared_down_KEGG, aes(x = transgenerational_shared_down_enrichment_scores, y = transgenerational_shared_down_pathways, color = transgenerational_shared_down_p_adjusted, size = transgenerational_shared_down_overlap)) +  geom_point() + geom_segment(aes(x = 0, xend = transgenerational_shared_down_enrichment_scores, y = transgenerational_shared_down_pathways, yend = transgenerational_shared_down_pathways, color = transgenerational_shared_down_p_adjusted), size = 1, alpha = 0.5) + 
  labs(title = "Shared Downregulated KEGG Pathways", x = "Enrichment Score", y = "Terms") +
  scale_color_continuous(name = "P-value", low = "blue", high = "red") +
  theme_minimal() +  theme(axis.text.y = element_text(size = 8), axis.title.y = element_text(size = 8))
print(transgenerational_shared_down_KEGG_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/transgenerational_comparison/shared_downregulated_KEGG_plot.png", plot = transgenerational_shared_down_KEGG_plot, width = 6, height = 4, dpi = 500)
```
```{r Toll-like receptor genes TPM dotplot}
# Read the TPM data from the CSV file
TLR_gene_data <- read.csv("/Volumes/angies_SSD/MICB_405/read_alignments/transgenerational_TLR_comparison.csv", header = TRUE, row.names = 1)
# Create data frame from CSV file
TPM_df <- list()
# Iterate over each gene
for (gene_name in rownames(TLR_gene_data)) {
  tpm_values <- as.vector(t(TLR_gene_data[gene_name, ]))
  TPM_df <- data.frame(
    Gene = rep(gene_name, length(tpm_values)),
    Condition = rep(c("F1", "F3", "P0"), times = c(5, 2, 3)),
    TPM = tpm_values
  )
 TPM_df[[gene_name]] <- TPM_df
}
TPM_df <- do.call(rbind, TPM_df)
# Calculate mean TPM for each Condition for error bars
mean_TPM_values <- aggregate(TPM ~ Condition, data = TPM_df, FUN = mean, na.rm = TRUE)  
TPM_condition <- c("F1", "F3", "P0")
TPM_df$Condition <- factor(TPM_df$Condition, levels = TPM_condition)
mean_TPM_values$Condition <- factor(mean_TPM_values$Condition, levels = TPM_condition)
# Plot results using ggplot2 package
TLR_TPM_plot <- ggplot(TPM_df, aes(x = Condition, y = TPM, fill= Condition)) + geom_dotplot(binaxis = 'y', stackdir = 'center', color = NA) + scale_fill_manual(values = c("F1" = "limegreen", "F3" = "skyblue", "P0" = "salmon")) + facet_wrap(~ Gene, scales = "free_y") +  theme_minimal() + theme(plot.background = element_blank(),  panel.background = element_blank(), strip.background = element_blank(), axis.line = element_line(color = "black"),strip.text = element_text(size = 8), axis.title = element_blank(), axis.text = element_text(size = 6), panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + guides(fill = FALSE, axis.line = element_line(size = 0.25))
  # Add mean lines for each condition
  TLR_TPM_plot <- TLR_TPM_plot + geom_segment(data = mean_TPM_values, aes(x = as.numeric(Condition) - 0.2, xend = as.numeric(Condition) + 0.2, y = TPM, yend = TPM), color = "black", size = 0.25)
print(TLR_TPM_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/TLR_TPM_dotplot.png", plot = TLR_TPM_plot, width = 6, height = 4, dpi = 500)
```

Comparison 2: Generational Comparison (F1 vs F3)
```{r Metadata table generation}
# Define metadata information
generational_sample_ids <- c("F1_1", "F1_2", "F1_3", "F1_4", "F1_5", "F3_1", "F3_2")
generational_condition <- c("F1", "F1", "F1", "F1", "F1", "F3", "F3")
generational_replicate <- c(1, 2, 3, 4, 5, 1, 2)
# Compile into data frame
generational_metadata <- data.frame(SampleID = generational_sample_ids, Condition = generational_condition, Replicate = generational_replicate)
```
```{r Differential gene expression analysis in DESeq2}
# Import count matrix file
generational_count_matrix <- read.table("/volumes/Angies_SSD/MICB_405/generational_comparison/generational_final_count_matrix.txt", header = TRUE, row.names = 1, sep = "\t")
# Set F1 as the reference level & design formula
generational_metadata$Condition <- as.factor(generational_metadata$Condition)
generational_metadata$Condition <- relevel(generational_metadata$Condition, ref = "F1")
design <- ~ Condition
# Build dataset object (dds) & complete DEG analysis
generational_dds <- DESeqDataSetFromMatrix(countData = generational_count_matrix, colData = generational_metadata, design = design)
generational_DESeq <- DESeq(generational_dds)
# Extract results & statistically significant DEGs
generational_DESeq_results <- results(generational_DESeq)
generational_DESeq_results <- as.data.frame(generational_DESeq_results)
generational_DESeq_results <- generational_DESeq_results[!is.na(generational_DESeq_results$padj), ]
generational_DEGs <- rownames(generational_DESeq_results)
generational_DESeq_results$Gene <- sgenerational_DEGs
write.csv(generational_DESeq_results, file = "/Volumes/Angies_SSD/MICB_405/generational_comparison/generational_DESeq2_results.csv", row.names = FALSE)
```
Visualization of Differential Gene Expression Analysis
```{r PCA plot - clustering of samples based on similarity in differentially expressed genes}
# Perform variance stabilizing transformation (VST) on dds
generational_dds <- vst(generational_dds)
# Perform principal component analysis & convert results into data frame
generational_pca <- prcomp(t(assay(generational_dds)))
generational_pca_df <- as.data.frame(generational_pca$x)
# Define condition colours for the PCA plot
generational_pca_df$Condition <- factor(generational_metadata$Condition)
# Create PCA plot using ggofortify package
generational_pca_plot <- autoplot(generational_pca, data = generational_pca_df) + geom_point(aes(color = Condition), size = 4) + geom_text(aes(label = generational_sample_ids), vjust = 1.5, hjust = 0, size = 2.5) + labs(color = "Condition") + theme(panel.grid = element_blank(), panel.background = element_rect(fill = "white"), axis.line = element_line(color = "black"),axis.title.x = element_text(size = 14), axis.title.y = element_text(size = 14)) 
# Display the PCA & save to a file
print(generational_pca_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/generational_comparison/generational_PCA_plot.png", plot = generational_pca_plot, width = 6, height = 4, dpi = 500)
```
```{r Heatmap - similarity in magnitude of normalized gene counts}
# Subset count matrix to include significant differentially expressed genes
generational_significant_DEGs <- rownames(generational_DESeq_results)[which(generational_DESeq_results$padj < 0.05)]  
generational_statistically_significant_count_matrix <- generational_count_matrix[generational_significant_DEGs, ]
# Calculate Z-scores
generational_z_scores <- t(scale(t(generational_statistically_significant_count_matrix)))
# Create heatmap plot using Pheatmap package
generational_heatmap <- pheatmap(generational_z_scores, cluster_rows = TRUE, cluster_cols = FALSE, scale = "none", main = "Heatmap of Differentially Expressed Genes", fontsize = 8, show_row_dendrogram = FALSE, show_col_dendrogram = FALSE)
# Display plot & save into a file
print(generational_heatmap)
ggsave("/Volumes/Angies_SSD/MICB_405/generational_comparison/generational_heatmap.png", plot = generational_heatmap, width = 6, height = 4, dpi = 500)
```
Gene Set Enrichment Analysis (GSEA) - determine functionality of differentially expressed genes
```{r Extract shared and uniquely expressed genes}
# Based on the workflow of this analysis, it is easier to re-run the DESeq during this step due to data transformation required
# Import count matrix file
generational_count_matrix <- read.table("/volumes/Angies_SSD/MICB_405/generational_comparison/generational_final_count_matrix.txt", header = TRUE, row.names = 1, sep = "\t")
# Set F1 as the reference level & design formula
generational_metadata$Condition <- as.factor(generational_metadata$Condition)
generational_metadata$Condition <- relevel(generational_metadata$Condition, ref = "F1")
design <- ~ Condition
# Build dataset object (dds) & complete DEG analysis
generational_dds <- DESeqDataSetFromMatrix(countData = generational_count_matrix, colData = generational_metadata, design = design)
generational_DESeq <- DESeq(generational_dds)
# Extract statistically significant DEGs in F3 generation
generational_F3_results <- results(generational_F1vF3_DESeq, contrast=c("Condition", "F3", "F1"))
generational_F3_results <- subset(generational_F3_results, padj < 0.05 & abs(log2FoldChange) > 1)
generational_F3_DEGs <- rownames(generational_F1_results)
generational_F3_results$Gene <- generational_F3_DEGs
write.csv(generational_F3_results, file = "/Volumes/Angies_SSD/MICB_405/generational_comparison/generational_F3_results.csv", row.names = FALSE)
```
```{r Enrichment Analysis Annotated to KEGG}
# WormBase Gene ID was identfied using DAVID Gene ID conversion from RefSeq RNA 
# Upregulated Genes in F3 generation
generational_F3_up_genes <- read.csv("/Volumes/Angies_SSD/MICB_405/generational_comparison/F3_upregulated_genes.csv")
generational_F3_up_KEGG <- enrichr(generational_F3_up_genes$Gene, KEGG_databases)
write.csv(generational_F3_up_KEGG, "/Volumes/Angies_SSD/MICB_405/generational_comparison/F3_upregulated_KEGG.csv", row.names = FALSE)
# Downregulated Genes in F3 generation
generational_F3_down_genes <- read.csv("/Volumes/Angies_SSD/MICB_405/generational_comparison/F3_downregulated_genes.csv")
generational_F3_down_KEGG <- enrichr(generational_F3_down_genes$Gene, KEGG_databases)
write.csv(generational_F3_down_KEGG, "/Volumes/Angies_SSD/MICB_405/generational_comparison/F3_downregulated_KEGG.csv", row.names = FALSE)
```
```{r KEGG dotplot - Pathways unique to F3 generation}
# Upregulated pathways in F1 generatoin
# Extract relevant information from EnrichR output
generational_F3_up_pathways <- generational_F3_up_KEGG$Term
generational_F3_up_enrichment_scores <- generational_F3_up_KEGG$Enrichment_score
generational_F3_up_p_adjusted <- generational_F3_up_KEGG$P_adjusted
generational_F3_up_overlap <- generational_F3_up_KEGG$Overlap
# Create dot plot using ggplot2
generational_F3_up_KEGG_plot <- ggplot(generational_F3_up_KEGG, aes(x = generational_F3_up_enrichment_scores, y = generational_F3_up_pathways, color = generational_F3_up_p_adjusted, size = generational_F3_up_overlap)) +  geom_point() + geom_segment(aes(x = 0, xend = generational_F3_up_enrichment_scores, y = generational_F3_up_pathways, yend = generational_F3_up_pathways, color = generational_F3_up_p_adjusted), size = 1, alpha = 0.5) + labs(title = "F3 Upregulated KEGG Pathways", x = "Enrichment Score", y = "Terms") +scale_color_continuous(name = "P-value", low = "blue", high = "red") + theme_minimal() +  theme(axis.text.y = element_text(size = 8), axis.title.y = element_text(size = 8))
print(generational_F3_up_KEGG_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/generational_comparison/generational_F3_upregulated_KEGG_plot.png", plot = generational_F3_up_KEGG_plot, width = 6, height = 4, dpi = 500)
# Downregulated KEGG patwhays in F1 generation
# Extract relevant information from EnrichR output
generational_F3_down_pathways <- generational_F3_down_KEGG$Term
generational_F3_down_enrichment_scores <- generational_F3_down_KEGG$Enrichment_score
generational_F3_down_p_adjusted <- generational_F3_down_KEGG$P_adjusted
generational_F3_down_overlap <- generational_F3_down_KEGG$Overlap
# Create dot plots for each dataset
generational_F3_down_KEGG_plot <- ggplot(generational_F3_down_KEGG, aes(x = generational_F3_down_enrichment_scores, y = generational_F3_down_pathways, color = generational_F3_down_p_adjusted, size = generational_F3_down_overlap)) +  geom_point() + geom_segment(aes(x = 0, xend = generational_F3_down_enrichment_scores, y = generational_F3_down_pathways, yend = generational_F3_down_pathways, color = generational_F3_down_p_adjusted), size = 1, alpha = 0.5) +labs(title = "F3 Downregulated KEGG Pathways", x = "Enrichment Score", y = "Terms") + scale_color_continuous(name = "P-value", low = "blue", high = "red") + theme_minimal() +  theme(axis.text.y = element_text(size = 8), axis.title.y = element_text(size = 8))
print(generational_F3_down_KEGG_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/generational_comparison/generational_F3_downregulated_KEGG_plot.png", plot = generational_F3_down_KEGG_plot, width = 6, height = 4, dpi = 500)
```

Comparison 3: F3 Intergenerational Comparison
```{r Metadata table generation}
# Define metadata information
intergenerational_sample_ids <- c("ethanol_1", "ethnaol_2", "water_1", "water_2", "water_3")
intergenerational_condition <- c("ethanol", "ethanol", "water", "water", "water")
intergenerational_replicate <- c(1, 2, 1, 2, 3, 1, 2, 3)
# Compile into data frame
intergenerational_metadata <- data.frame(SampleID = intergenerational_sample_ids, Condition = intergenerational_condition, Replicate = intergenerational_replicate)
```
```{r Differential gene expression analysis in DESeq2}
# Import count matrix file
intergenerational_count_matrix <- read.table("/Volumes/Angies_SSD/MICB_405/intergenerational_comparison/intergenerational_final_count_matrix.txt", header = TRUE, row.names = 1, sep = "\t")
# Set water as the reference level & design formula
intergenerational_metadata$Condition <- as.factor(intergenerational_metadata$Condition)
intergenerational_metadata$Condition <- relevel(intergenerational_metadata$Condition, ref = "water")
design <- ~ Condition
# Build dataset object (dds) & complete DEG analysis
intergenerational_dds <- DESeqDataSetFromMatrix(countData = intergenerational_count_matrix, colData = intergenerational_metadata, design = design)
intergenerational_DESeq <- DESeq(intergenerational_dds)
# Extract results & statistically significant DEGs
intergenerational_DESeq_results <- results(intergenerational_DESeq)
intergenerational_DESeq_results <- as.data.frame(intergenerational_DESeq_results)
intergenerational_DESeq_results <- intergenerational_DESeq_results[!is.na(intergenerational_DESeq_results$padj), ]
intergenerational_DEGs <- rownames(intergenerational_DESeq_results)
intergenerational_DESeq_results$Gene <- intergenerational_DEGs
write.csv(intergenerational_DESeq_results, file = "/Volumes/Angies_SSD/MICB_405/intergenerational_comparison/intergenerational_DESeq2_results.csv", row.names = FALSE)
```
Visualization of Differential Gene Expression Analysis
```{r PCA plot - clustering of samples based on similarity in differentially expressed genes}
# Perform variance stabilizing transformation (VST) on dds
intergenerational_dds <- vst(intergenerational_dds)
# Perform principal component analysis & convert results into data frame
intergenerational_pca <- prcomp(t(assay(intergenerational_dds)))
intergenerational_pca_df <- as.data.frame(intergenerational_pca$x)
# Define condition colours for the PCA plot
intergenerational_pca_df$Condition <- factor(intergenerational_metadata$Condition)
# Create PCA plot using ggofortify package
intergenerational_pca_plot <- autoplot(intergenerational_pca, data = intergenerational_pca_df) + geom_point(aes(color = Condition), size = 4) + geom_text(aes(label = intergenerational_sample_ids), vjust = 1.5, hjust = 0, size = 2.5) + labs(color = "Condition") + theme(panel.grid = element_blank(), panel.background = element_rect(fill = "white"), axis.line = element_line(color = "black"),axis.title.x = element_text(size = 14), axis.title.y = element_text(size = 14)) 
# Display the PCA & save to a file
print(intergenerational_pca_plot)
ggsave("/Volumes/Angies_SSD/MICB_405/intergenerational_comparison/intergenerational_PCA_plot.png", plot = intergenerational_pca_plot, width = 6, height = 4, dpi = 500)
```
```{r Heatmap - similarity in magnitude of normalized gene counts}
# Subset count matrix to include significant differentially expressed genes
intergenerational_significant_DEGs <- rownames(intergenerational_DESeq_results)[which(intergenerational_DESeq_results$padj < 0.05)]  
intergenerational_statistically_significant_count_matrix <- intergenerational_count_matrix[intergenerational_significant_DEGs, ]
# Calculate Z-scores
intergenerational_z_scores <- t(scale(t(intergenerational_statistically_significant_count_matrix)))
# Create heatmap plot using Pheatmap package
intergenerational_heatmap <- pheatmap(intergenerational_z_scores, cluster_rows = TRUE, cluster_cols = FALSE, scale = "none", main = "Heatmap of Differentially Expressed Genes", fontsize = 8, show_row_dendrogram = FALSE, show_col_dendrogram = FALSE)
# Display plot & save into a file
print(intergenerational_heatmap)
ggsave("/Volumes/Angies_SSD/MICB_405/intergenerational_comparison/intergenerational_heatmap.png", plot = intergenerational_heatmap, width = 6, height = 4, dpi = 500)
```
Gene Set Enrichment Analysis (GSEA) - determine functionality of differentially expressed genes
```{r Venn Diagram of shared and uniquely expressed genes}
# Import count matrix file
intergenerational_count_matrix <- read.table("/Volumes/Angies_SSD/MICB_405/intergenerational_comparison/intergenerational_final_count_matrix.txt", header = TRUE, row.names = 1, sep = "\t")
# Set water as the reference level & design formula
intergenerational_metadata$Condition <- as.factor(intergenerational_metadata$Condition)
intergenerational_metadata$Condition <- relevel(intergenerational_metadata$Condition, ref = "water")
design <- ~ Condition
# Build dataset object (dds) & complete DEG analysis
intergenerational_dds <- DESeqDataSetFromMatrix(countData = intergenerational_count_matrix, colData = intergenerational_metadata, design = design)
intergenerational_DESeq <- DESeq(intergenerational_dds)
# Extract statistically significant DEGs for each condition comparison
intergenerational_ethanol_results <- results(intergenerational_DESeq, contrast=c("Condition", "water", "ethanol"))
intergenerational_ethanol_results <- subset(intergenerational_ethanol_results, padj < 0.05 & abs(log2FoldChange) > 1)
intergenerational_ethanol_DEGs <- rownames(intergenerational_ethanol_results)
intergenerational_ethanol_results$Gene <- intergenerational_ethanol_DEGs
write.csv(intergenerational_ethanol_results, file = "/Volumes/Angies_SSD/MICB_405/integenerational_comparison/intergenerational_water_results.csv", row.names = FALSE)
# Extract gene identifiers of significant DEGs in the water condition
intergenerational_water_DEGs <- rownames(intergenerational_water_results)
intergenerational_gene_lists <- list(Condition1 = intergenerational_ethanol_DEGs, Condition2 = intergenerational_water_DEGs)
# Create Venn diagram using VennDiagram package
intergenerational_venn_plot <- venn.diagram(x = intergenerational_gene_lists, category.names = c("ethanol", "water"), scaled = FALSE, filename = NULL,cat.pos = 0, cat.dist = 0.04, cat.cex = 1.8, fill = c("lightgreen", "lightblue"), cex.prop = 8, cex = 1.5)
# Save the Venn diagram as a PDF
pdf("/volumes/Angies_SSD/MICB_405/intergenerational_comparison/intergenerational_venn_diagram.pdf", width = 6, height = 4)  
grid.draw(intergenerational_venn_plot)
dev.off()
```
