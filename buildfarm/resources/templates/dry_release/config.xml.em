<?xml version='1.0' encoding='UTF-8'?>
<project>
  <actions/>
  <description>Generated job to create binary debs for dry stack "@(PACKAGE)". DO NOT EDIT BY HAND. Generated by catkin-debs/scripts/create_release_jobs.py for @(USERNAME) at @(TIMESTAMP)</description>
  <logRotator>
    <daysToKeep>30</daysToKeep>
    <numToKeep>10</numToKeep>
    <artifactDaysToKeep>30</artifactDaysToKeep>
    <artifactNumToKeep>-1</artifactNumToKeep>
  </logRotator>
  <keepDependencies>false</keepDependencies>
  <properties>
  </properties>
  <scm class="hudson.scm.SubversionSCM">
    <locations>
      <hudson.scm.SubversionSCM_-ModuleLocation>
        <remote>https://code.ros.org/svn/release/trunk</remote>
        <local>release</local>
      </hudson.scm.SubversionSCM_-ModuleLocation>
      <hudson.scm.SubversionSCM_-ModuleLocation>
        <remote>https://code.ros.org/svn/ros/stacks/ros_release/trunk</remote>
        <local>ros_release</local>
      </hudson.scm.SubversionSCM_-ModuleLocation>
    </locations>
    <excludedRegions></excludedRegions>
    <includedRegions></includedRegions>
    <excludedUsers></excludedUsers>
    <excludedRevprop></excludedRevprop>
    <excludedCommitMessages></excludedCommitMessages>
    <workspaceUpdater class="hudson.scm.subversion.UpdateUpdater"/>
  </scm>
  <assignedNode>debbuild</assignedNode>
  <canRoam>false</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>true</blockBuildWhenUpstreamBuilding>
  <authToken>RELEASE_BUILD_DEBS</authToken>
  <triggers class="vector"/>
  <concurrentBuild>false</concurrentBuild>
  <builders>
@[if not IS_METAPACKAGES]@
    <hudson.plugins.groovy.SystemGroovy plugin="groovy@@1.12">
      <scriptSource class="hudson.plugins.groovy.StringScriptSource">
        <command>
// VERFIY THAT NO UPSTREAM PROJECT IS BROKEN
import hudson.model.Result

println ""
println "Verify that no upstream project is broken"
println ""

project = Thread.currentThread().executable.project

for (upstream in project.getUpstreamProjects()) {
	abort = upstream.getNextBuildNumber() == 1

	if (!abort) {
		lb = upstream.getLastBuild()
		if (!lb) continue

		r = lb.getResult()
		if (!r) continue

		abort = r.isWorseOrEqualTo(Result.FAILURE)
	}

	if (abort) {
		println "Aborting build since upstream project '" + upstream.name + "' is broken"
		println ""
		throw new InterruptedException()
	}
}

println "All upstream projects are (un)stable"
println ""
</command>
      </scriptSource>
      <bindings/>
      <classpath/>
    </hudson.plugins.groovy.SystemGroovy>
@[end if]@
    <hudson.tasks.Shell>
      <command>@(COMMAND)</command>
    </hudson.tasks.Shell>
@[if not IS_METAPACKAGES]@
    <hudson.plugins.groovy.SystemGroovy plugin="groovy@@1.12">
      <scriptSource class="hudson.plugins.groovy.StringScriptSource">
        <command>
// CHECK FOR "HASH SUM MISMATCH" AND RETRIGGER JOB
// only triggered when previous build step was successful
import java.io.BufferedReader
import java.util.regex.Matcher
import java.util.regex.Pattern

import hudson.model.Cause
import hudson.model.Result

println ""
println "Check for 'Hash Sum mismatch'"
println ""

build = Thread.currentThread().executable

// search build output for hash sum mismatch
r = build.getLogReader()
br = new BufferedReader(r)
pattern = Pattern.compile(".*W: Failed to fetch .* Hash Sum mismatch.*")
def line
while ((line = br.readLine()) != null) {
	if (pattern.matcher(line).matches()) {
		println "Aborting build due to 'hash sum mismatch'"
		// check if previous build was already rescheduling to avoid infinite loop
		pr = build.getPreviousBuild().getLogReader()
		if (pr) {
			pbr = new BufferedReader(pr)
			while ((line = pbr.readLine()) != null) {
				if (pattern.matcher(line).matches()) {
					println "Skip rescheduling new build since this was already a rescheduled build"
					println ""
					return
				}
			}
		}
		println "Immediately rescheduling new build..."
		println ""
		build.project.scheduleBuild(new Cause.UserIdCause())
		throw new InterruptedException()
	}
}
println "Pattern not found in build log"
println ""
</command>
      </scriptSource>
      <bindings/>
      <classpath/>
    </hudson.plugins.groovy.SystemGroovy>
@[end if]@
  </builders>
  <publishers>
    <org.jvnet.hudson.plugins.groovypostbuild.GroovyPostbuildRecorder plugin="groovy-postbuild@@1.8">
      <groovyScript>
// CHECK FOR VARIOUS REASONS TO RETRIGGER JOB
// also triggered when a build step has failed
import hudson.model.Cause

def reschedule_build(msg) {
	pb = manager.build.getPreviousBuild()
	if (pb) {
		pba = pb.getBadgeActions()
		if (pba.size() > 0) {
			manager.addInfoBadge("Log contains '" + msg + "' - skip rescheduling new build since this was already a rescheduled build")
			return
		}
	}
	manager.addInfoBadge("Log contains '" + msg + "' - scheduled new build...")
	manager.build.project.scheduleBuild(new Cause.UserIdCause())
}

if (manager.logContains(".*W: Failed to fetch .* Hash Sum mismatch.*")) {
	reschedule_build("Hash Sum mismatch")
} else if (manager.logContains(".*The lock file '/var/www/repos/building/db/lockfile' already exists.*")) {
	reschedule_build("building/db/lockfile already exists")
} else if (manager.logContains(".*E: Could not get lock /var/lib/dpkg/lock - open \\(11: Resource temporarily unavailable\\).*")) {
	reschedule_build("dpkg/lock temporary unavailable")
} else if (manager.logContains(".*ERROR: cannot download default sources list from:.*")) {
	reschedule_build("cannot download default sources list")
} else if (manager.logContains(".*ERROR: Not all sources were able to be updated.*")) {
	reschedule_build("Not all sources were able to be updated")
}
</groovyScript>
      <behavior>0</behavior>
    </org.jvnet.hudson.plugins.groovypostbuild.GroovyPostbuildRecorder>
    <hudson.tasks.BuildTrigger>
      <childProjects>@(','.join(CHILD_PROJECTS))</childProjects>
      <threshold>
        <name>SUCCESS</name>
        <ordinal>0</ordinal>
        <color>BLUE</color>
      </threshold>
    </hudson.tasks.BuildTrigger>
    <hudson.tasks.Mailer>
      <recipients>@(NOTIFICATION_EMAIL)</recipients>
      <dontNotifyEveryUnstableBuild>false</dontNotifyEveryUnstableBuild>
      <sendToIndividuals>false</sendToIndividuals>
    </hudson.tasks.Mailer>
  </publishers>
  <buildWrappers/>
</project>
