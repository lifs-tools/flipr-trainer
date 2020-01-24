#!/usr/bin/env groovy
def cli = new CliBuilder(usage:'create-docx')
cli.d(longOpt: 'dir', args:1, argName: 'dir', 'The directory to collect images from.')
cli.o(longOpt:'outfile', args:1, argName:'outfile', 'The file to write to (without adoc file extension).')
cli.t(longOpt:'title',args:1, argName:'title', 'The output file document title.')
cli.p(longOpt:'platform',args:1,argName:'platform', 'The MS platform used (full name).')
def options = cli.parse(args)

@groovy.transform.Canonical
class Figure {
  String title
  String path
}

@groovy.transform.Canonical
class FliprInstance {
  String name
  String instrument
  String origin
  String group
  String species
  String precursorAdduct
  Map<Integer, Figure> figures = [:] as TreeMap
}

if (!options || options.h || !options.d || !options.o || !options.t || !options.p) {
    cli.usage()
    System.exit(1)
}
if(new File(options.d).isDirectory()) {
  println "Writing to ${options.o}"
  def instancesMap = [:] as TreeMap
  new File(options.d).traverse(type: groovy.io.FileType.FILES, nameFilter: ~/.*.png/) { it ->
    def instanceRelativePath = new File(options.o).getParentFile().toPath().relativize(it.toPath())
    //println "Relative path from output file to instance directory: ${instanceRelativePath}"
    def parent = it.getParentFile()
    if(!instancesMap.containsKey(parent)) {
      println "Found instance directory $parent"
      instancesMap[parent]=[]
      def fipFile = new File(parent, parent.getName()+"_fip.tsv")
      fipFile.withReader { 
	def headerListWithIndex = it.readLine().split('\t').toList().withIndex()
        def headerMap = [:].withDefault { [] }
	headerListWithIndex.each {
	  headerMap[it[0]] << it[1]
	}
	//println headerMap
        def firstContentRowList = it.readLine().split('\t')
	//println firstContentRowList
        //species precursorAdduct fragment group origin instrument
        
        def fliprInstance = [
         name:parent,
         instrument:firstContentRowList[headerMap['instrument']][0],
         origin:firstContentRowList[headerMap['origin']][0],
         species:firstContentRowList[headerMap['species']][0],
         precursorAdduct:firstContentRowList[headerMap['precursorAdduct']][0],
         group:firstContentRowList[headerMap['group']][0]
        ] as FliprInstance
	instancesMap[parent] = fliprInstance
      } 
    }

    def title = ""
    def index = -1
    if(instanceRelativePath ==~ /.*-fit\.png/) {
      title = "Nonlinear fit"
      index = 0
    } else if(instanceRelativePath ==~ /.*-residuals\.png/) {
      title = "Residuals of nonlinear fit"
      index = 1
    } else if(instanceRelativePath ==~ /.*-residuals-qq\.png/) {
      title = "Quantile-quantile plot of residuals"
      index = 2
    } else if(instanceRelativePath ==~ /.*-residuals-mean-ssq\.png/) {
      title = "Normalized sum-of-squares of the residuals"
      index = 3
    } else if(instanceRelativePath ==~ /.*-samples-per-combinationId\.png/) {
      title = "Number of samples used for training per combination Id"
      index = 4
    }
    if(!title.isEmpty()) {
      instancesMap[parent].figures[index] = new Figure(title:title, path:instanceRelativePath)
    }
  }
//  println instancesMap
def outFile = new File(options.o)
def basedir = outFile.getParentFile()
def basename = outFile.name.take(outFile.name.lastIndexOf('.'))
println "Using basename ${basename}"
def titleFile = new File(basedir, basename+"-title.adoc")
println "Writing title file ${titleFile}"
titleFile.withWriter { out ->
  def header = 
    """\
:doctype: article
:doctitle: Supplementary Material S3 - Modeling Results for the ${options.p} platform for:
:docsubtitle: LipidCreator: A workbench to probe the lipidomic landscape
:authors: Bing Peng, Dominik Kopczynski 
:sectnums:
:pagenums!:
ifdef::backend-pdf[:notitle:]
ifdef::backend-pdf[]
[discrete]
= {doctitle} 
[discrete]
== {docsubtitle}
*Bing Peng*^[1,9,14]^, 
*Dominik Kopczynski*^[1,9,14]^, 
*Brian Pratt*^[2]^, 
*Christer Ejsing*^[3,4]^, 
*Bo Burla*^[5]^,
*Martin Hermansson*^[3]^, 
*Peter Imre Benke*^[6]^, 
*Sock Hwee Tan*^[7,8]^,
*Mark Y. Chan*^[7,8,9]^,
*Federico Torta*^[6]^,
*Dominik Schwudke*^[10]^, 
*Sven Meckelmann*^[11]^, 
*Cristina Coman*^[1,8]^, 
*Oliver J. Schmitz*^[11]^,
*Brendan MacLean*^[2]^,
*Oliver Borst*^[12]^,
*Markus Wenk*^[5,6]^,
*Nils Hoffmann*^[1]^,
*Robert Ahrends*^[1,13,15]^{empty} +
^1^Leibniz-Institut für Analytische Wissenschaften-ISAS-e.V., Dortmund, Germany{empty} +
^2^University of Washington, Department of Genome Sciences, Seattle, USA{empty} +
^3^Department of Biochemistry and Molecular Biology, University of Southern Denmark, Odense, Denmark{empty} +
^4^Cell Biology and Biophysics Unit, European Molecular Biology Laboratory, Heidelberg, Germany{empty} +
^5^Singapore Lipidomics Incubator (SLING), Life Science Institute, National University of Singapore, Singapore{empty} +
^6^Singapore Lipidomics Incubator (SLING), Department of Biochemistry, Yong Loo Lin School of Medicine, National University of Singapore, Singapore{empty} +
^7^Department of Medicine, Yong Loo Lin School of Medicine, National University Hospital, Singapore{empty} + 
^8^Cardiovascular Research Institute, National University of Singapore, Singapore{empty} +
^9^National University Heart Centre, National University Health System, Singapore{empty} +
^10^Research Center Borstel, Leibniz Center for Medicine and Biosciences, Borstel, Germany{empty} +
^11^Institute of Applied Analytical Chemistry, University of Duisburg-Essen, Essen, Germany{empty} +
^12^Department of Cardiology and Cardiovascular Medicine, University of Tübingen, Tübingen, Germany{empty} +
^13^Institute of Analytical Chemistry, University of Vienna, Währinger Strasse 38, 1090 Vienna, Austria{empty} +
^14^two authors contributed equally to this work{empty} +
^15^Corresponding author{empty}
endif::[]
    """.stripIndent()
 out.println header
}

println "Rendering title file ${titleFile} to pdf"
def genTitlePage = "asciidoctor-pdf -a pdf-stylesdir=resources/theme -a pdf-style=basic -a allow-uri-read -a pdf-fontsdir=/usr/share/fonts/truetype/msttcorefonts/ ${titleFile}".execute()
genTitlePage.waitForProcessOutput(System.out, System.err)
genTitlePageExitValue = genTitlePage.exitValue()
if(genTitlePageExitValue!=0) {
  println "Execution of title page generation failed with code ${genTitlePageExitValue}"
  System.exit(genTitlePageExitValue)
}

println "Writing document file to ${outFile}"
outFile.withWriter { out ->
def header =
"""\
= ${options.t}
:doctype: article
:notitle:
:front-cover-image: image:${basename+'-title.pdf'}[]
:sectnums:
:pagenums:
:pdf-page-layout: portrait
:pdf-page-size: a4
:imagesdir:  
:toc:
:toclevels: 4
""".stripIndent()
  out.println header
  out.println "== ${options.p}"
  instancesMap.each { k,v ->
   if(v.figures.isEmpty()) {
     println "Skipping empty results for ${k}"
   } else {
     out.println "[#${v.group}]"
     out.println "=== ${v.species} ${v.precursorAdduct} ${v.group}"
     v.figures.each { fk, figure ->
       //==== ${figure.title}
       def figureBlock =
       """\
       [#img-${figure.title.replaceAll(' ','_')}-${v.group}]
       .${figure.title} 
       image::${figure.path.replaceAll('\\{','\\\\{')}[${figure.title},pdfwidth=80%,scaledwidth=80%]
       """.stripIndent()
       out.println figureBlock
     }
   }
   out.println "<<<"
  }
  out.println ""
}
println "Rendering document file ${outFile} to pdf"
def genDocument = "asciidoctor-pdf -a pdf-stylesdir=resources/theme -a pdf-style=basic -a allow-uri-read -a pdf-fontsdir=/usr/share/fonts/truetype/msttcorefonts/ ${outFile}".execute()
genDocument.waitForProcessOutput(System.out, System.err)
genDocumentExitValue = genDocument.exitValue()
if(genDocumentExitValue!=0) {
  println "Execution of content page generation failed with code ${genDocumentExitValue}"
  System.exit(genDocumentExitValue)
}

} else {
  println "${options.d} does not exist!"
  System.exit(1)
}
