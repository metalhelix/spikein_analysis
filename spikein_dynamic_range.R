
args = commandArgs(TRUE)

name <- args[1]
rpkms_filename <- args[2]
output_dir <- args[3]
expected_filename <- args[4]

# expected_filename <- "data/expected.txt"

# output_dir <- "ercc_spikeins"
dir.create(output_dir, recursive = T)
output_prefix <- paste(output_dir, "spikeins_", sep = "/")


spikein_rpkms <- read.table(rpkms_filename, quote = '', header = T, sep = '\t', skip = 0, comment.char = "")
expected <- read.table(expected_filename, quote = '', header = T, sep = '\t', skip = 0, comment.char = "")
colnames(expected) <- c("row", "name", "subgroup", "mix_1", "mix_2", "expected_fold_change", "log2_fold_change", "dCt")

spikes_merged <- merge(spikein_rpkms, expected, by.x = "name", by.y = "name", sort = F)

filename <- paste(output_prefix, name, ".", "rpkms_with_mix", ".txt", sep = "")
write.table(spikes_merged, file = filename, quote = FALSE, sep = "\t", row.names = FALSE)

spikes_merged <- subset(spikes_merged, rpkm >= 5)
spikes_merged$group <- factor(spikes_merged$subgroup)
spikes_merged$color[spikes_merged$group == "A"] <- "red"
spikes_merged$color[spikes_merged$group == "B"] <- "green"
spikes_merged$color[spikes_merged$group == "C"] <- "blue"
spikes_merged$color[spikes_merged$group == "D"] <- "darkgoldenrod"

#fit <- lm(spikes_merged$actual_log2_fold_change ~ spikes.plot$expected_log2_fold_change, data = spikes.plot)

filename <- paste(output_prefix, name, "_", "expected_vs_mix_1", ".png", sep = "")
png(filename, height=500, width=800)
plot(log2(spikes_merged$mix_1), log2(spikes_merged$rpkm), col = spikes_merged$color, xlab = "Log2(pM) Mix 1", ylab = "Log2(RPKM Mix 1)", main = paste(name, " vs Mix 1", sep=""))
fit <- lm(log2(spikes_merged$rpkm) ~ log2(spikes_merged$mix_1), data = spikes_merged)
abline(fit)
fit_r_squared <- round(summary(fit)$r.squared, digits = 3)
fit_slope <- round(fit$coefficients[[2]], digits = 3)
slope_text <- paste("Slope = ", fit_slope, sep = "")
text(12, mean(log2(spikes_merged$rpkm)), labels = slope_text)
r2_text <- paste("R2 = ", fit_r_squared, sep = "")
text(12, mean(log2(spikes_merged$rpkm)) - 0.8, labels = r2_text)
dev.off()

filename <- paste(output_prefix, name, "_", "expected_vs_mix_2", ".png", sep = "")
png(filename, height=500, width=800)
plot(log2(spikes_merged$mix_2), log2(spikes_merged$rpkm), col = spikes_merged$color, xlab = "Log2(pM) Mix 2", ylab = "Log2(RPKM Mix 2)", main = paste(name, " vs Mix 2", sep=""))
fit <- lm(log2(spikes_merged$rpkm) ~ log2(spikes_merged$mix_2), data = spikes_merged)
abline(fit)
fit_r_squared <- round(summary(fit)$r.squared, digits = 3)
fit_slope <- round(fit$coefficients[[2]], digits = 3)
slope_text <- paste("Slope = ", fit_slope, sep = "")
text(12, mean(log2(spikes_merged$rpkm)), labels = slope_text)
r2_text <- paste("R2 = ", fit_r_squared, sep = "")
text(12, mean(log2(spikes_merged$rpkm)) - 0.8, labels = r2_text)
dev.off()

#plot(log2(spikes_merged$mix_1), log2(spikes_merged$rpkm))

#plot(log2(spikes_merged$mix_2), log2(spikes_merged$rpkm))

