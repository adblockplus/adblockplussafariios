We welcome your contributions to this open-source project on Gitlab. We have a
few simple guidelines for you to follow.

### Development

Our active branch for development is `develop`. Please base your changes off of
that branch.

### Issues

There may be an issue that relates to your development. Please first check the
existing issues.

If needed, create a new issue with the following descriptions.

* The background of the problem/change. If describing a problem, please add your
  testing environment.
* Your proposed changes, if any.
* The conditions that indicate successful resolution of the problem/change.

### Merge requests

Also commonly known as a 'pull request'.

#### Merge request title format

If the merge request is for an existing issue, please use the following format
as its title. Note that the hash (`#`) character links the merge request to the
original issue.

    Issue #XXXX - A brief description of what was changed

For example:

    Issue #6570 - Updated map/flatMap usage for Swift 4.1

If the merge request is not for something that requires an issue, please use the
following format as its title.

    Noissue - A brief description of what was changed

For example:

    Noissue - Fixed spelling of "Xcode"

If the merge request requires an issue, please first create an issue.

Your request will be reviewed and commented on if further changes are needed and
you will be notified when it is accepted.

### Branches

Please submit changes as a _single commit_ in a _single branch._

#### Branch title format

Please title your branch after the issue using a single dash (`-`) character as
a separator without a hash (`#`) character.  

For example:

    Issue-6570

or

    Noissue-Fixed-Spelling

#### Your commit

Please have your commit message _match the title of the merge request_.

For example:

    Issue #6570 - Updated map/flatMap usage for Swift 4.1

or

    Noissue - Fixed spelling of "Xcode"

Reducing your development branch to a single commit may require squashing your
commits.

### Your code

We use SwiftLint to check Swift code formatting. The rules are available
[here](https://gitlab.com/eyeo/adblockplus/adblockplussafariios/blob/master/.swiftlint.yml).

Code that can be verified by unit tests is preferred.

### Revisions during review

Subsequent changes to your commit can be made by re-adding your commit with
changes after resetting your branch HEAD to _the commit before your commit under
review_. The commit with changes can then be force pushed to your REMOTE branch.
Each version will be viewable in the Changes section of the merge request.
