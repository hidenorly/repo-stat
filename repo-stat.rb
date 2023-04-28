#!/usr/bin/ruby

# Copyright 2023 hidenorly
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'optparse'
require_relative 'ExecUtil'
require_relative 'TaskManager'
require_relative "RepoUtil"
require_relative "Reporter"


class ExecDiff < TaskAsync
	def initialize(resultCollector, srcPath, dstPath, relativePath, options)
		super("ExecDiff::#{srcPath} #{dstPath} #{relativePath}")
		@resultCollector = resultCollector
		@srcPath = srcPath
		@srcGitOpt = options[:srcGitOpt]
		@dstPath = dstPath
		@dstGitOpt = options[:dstGitOpt]
		@relativePath = relativePath
		@options = options
	end

	def execute
		patchDir = RepoUtil.getFlatFilenameFromGitPath(@relativePath)

		srcPath = @srcPath+"/"+@relativePath
		dstPath = @dstPath+"/"+@relativePath

		if File.directory?(srcPath) && File.directory?(dstPath) then
			mode = @options[:mode].split(",")
			theResult = {}
			mode.each do |aSection|
				aSection.strip!
				aSection.downcase!
				theResult[aSection] = 0
			end

			#Avoid git in git situation then do following instead of diff -r -x .git in the git
			srcModifiedFiles = GitUtil.getFilesWithGitOpts(srcPath, @srcGitOpt)
			dstModifiedFiles = GitUtil.getFilesWithGitOpts(dstPath, @dstGitOpt)
			targetModifiedFiles = srcModifiedFiles.union(dstModifiedFiles)

			targetModifiedFiles.each do |aTargeFile|
				if !FileClassifier.isBinaryFile( aTargeFile ) then
					targetSrcFile = srcPath + "/" + aTargeFile
					targetDstFile = dstPath + "/" + aTargeFile
					mode.each do |aSection|
						aSection.strip!
						aSection.downcase!
						if ( aSection == "existingonly" && srcModifiedFiles.include?(aTargeFile) && dstModifiedFiles.include?(aTargeFile) ) || aSection == "inclnewfile" then
							exec_cmd = "diff -U 0"
							exec_cmd = exec_cmd + " -N" if aSection == "inclnewfile"
							exec_cmd = exec_cmd + " #{Shellwords.shellescape(targetSrcFile)} #{Shellwords.shellescape(targetDstFile)}"
							exec_cmd = exec_cmd + " 2>/dev/null"
							exec_cmd = exec_cmd + " | grep -Ev \'^(\\+\\+\\+|\\-\\-\\-)\' | grep \'^\\+\' | wc -l"
							result = ExecUtil.getExecResultEachLine(exec_cmd)
							theResult[aSection] = theResult[aSection].to_i + result[0].to_i
						end
					end
				end
			end
			result = ""
			mode.each do |aSection|
				aSection.strip!
				aSection.downcase!
				result = result + (!result.empty? ? "," : "") + theResult[aSection].to_s
			end
			@resultCollector.onResult( patchDir, result )
		end
		_doneTask()
	end
end


#---- main --------------------------
options = {
	:manifestFile => RepoUtil::DEF_MANIFESTFILE,
	:logDirectory => Dir.pwd,
	:disableLog => false,
	:verbose => false,
	:srcDir => ".",
	:srcGitOpt => ".",
	:dstDir => ".",
	:dstGitOpt => ".",
	:gitPath => nil,
	:prefix => "",
	:mode=>"existingOnly,inclNewFile",
	:reportOutPath => nil,
	:numOfThreads => TaskManagerAsync.getNumberOfProcessor()
}


opt_parser = OptionParser.new do |opts|
	opts.banner = "Usage: -s sourceRepoDir -t targetRepoDir"

	opts.on("", "--manifestFile=", "Specify manifest file (default:#{options[:manifestFile]})") do |manifestFile|
		options[:manifestFile] = manifestFile
	end

	opts.on("-j", "--numOfThreads=", "Specify number of threads (default:#{options[:numOfThreads]})") do |numOfThreads|
		options[:numOfThreads] = numOfThreads
	end

	opts.on("-v", "--verbose", "Enable verbose status output (default:#{options[:verbose]})") do
		options[:verbose] = true
	end

	opts.on("-s", "--source=", "Specify source repo dir.") do |src|
		options[:srcDir] = src
	end

	opts.on("", "--sourceGitOpt=", "Specify gitOpt for source repo dir.") do |srcGitOpt|
		options[:srcGitOpt] = srcGitOpt
	end

	opts.on("-t", "--target=", "Specify target repo dir.") do |dst|
		options[:dstDir] = dst
	end

	opts.on("", "--targetGitOpt=", "Specify gitOpt for target repo dir.") do |dstGitOpt|
		options[:dstGitOpt] = dstGitOpt
	end

	opts.on("-g", "--gitPath=", "Specify target git path (regexp) if you want to limit to execute the git only") do |gitPath|
		options[:gitPath] = gitPath
	end

	opts.on("-p", "--prefix=", "Specify prefix if necessary to add for the path") do |prefix|
		options[:prefix] = prefix
	end

	opts.on("-m", "--mode=", "Specify mode (default:#{options[:mode]})") do |mode|
		options[:mode] = mode
	end

	opts.on("-o", "--output=", "Specify report file path )") do |reportOutPath|
		options[:reportOutPath] = reportOutPath
	end
end.parse!

options[:srcDir] = File.expand_path(options[:srcDir])
options[:dstDir] = File.expand_path(options[:dstDir])

# common
resultCollector = ResultCollectorHash.new()
taskMan = ThreadPool.new( options[:numOfThreads].to_i )

if ( !RepoUtil.isRepoDirectory?(options[:srcDir]) ) then
	puts "-s #{options[:srcDir]} is not repo directory"
	exit(-1)
end

if ( !RepoUtil.isRepoDirectory?(options[:dstDir]) ) then
	puts "-t #{options[:dstDir]} is not repo directory"
	exit(-1)
end

matched, missed = RepoUtil.getRobustMatchedGitsWithFilter( options[:srcDir], options[:dstDir], options[:manifestFile], options[:gitPath])

matched.each do | path, gitPath |
	puts path if options[:verbose]
	taskMan.addTask( ExecDiff.new(resultCollector, options[:srcDir], options[:dstDir], path, options) )
end

taskMan.executeAll()
taskMan.finalize()

result = resultCollector.getResult()
result = result.sort

reporter = CsvReporter.new( options[:reportOutPath] )

result.each do | path, result |
	reporter.println( "#{options[:prefix]}#{path},#{result}" )
end

reporter.close()
