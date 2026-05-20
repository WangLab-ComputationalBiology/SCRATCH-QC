class Utils {
    static def check_max(obj, type, params) {
        if (type == 'memory') {
            try {
                def max = params.max_memory as nextflow.util.MemoryUnit
                return obj.compareTo(max) == 1 ? max : obj
            } catch (all) {
                println "   ### ERROR ###   Max memory '${params.max_memory}' is not valid! Using default value: $obj"
                return obj
            }
        } else if (type == 'time') {
            try {
                def max = params.max_time as nextflow.util.Duration
                return obj.compareTo(max) == 1 ? max : obj
            } catch (all) {
                println "   ### ERROR ###   Max time '${params.max_time}' is not valid! Using default value: $obj"
                return obj
            }
        } else if (type == 'cpus') {
            try {
                return Math.min(obj, params.max_cpus as int)
            } catch (all) {
                println "   ### ERROR ###   Max cpus '${params.max_cpus}' is not valid! Using default value: $obj"
                return obj
            }
        }
    }
}
