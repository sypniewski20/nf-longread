def readBam(bam_sheet) {

    Channel
        .fromPath(bam_sheet)
        .splitCsv(header: true, sep: ',')
        .map { row ->
            tuple(
                row.sampleID,
                file(row.bam, checkIfExists: true),
                file(row.bai, checkIfExists: true)
            )
        }
}