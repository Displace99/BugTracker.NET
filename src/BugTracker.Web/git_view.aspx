<%@ Page language="C#" CodeBehind="git_view.aspx.cs" Inherits="btnet.git_view" AutoEventWireup="True" %>
<!-- #include file = "inc.aspx" -->
<script language="C#" runat="server">


// *****>>>>>> Intentionally not putting copyright in HTML comment, because of text/plain content type.
//Copyright 2002-2011 Corey Trager
//Distributed under the terms of the GNU General Public License


///////////////////////////////////////////////////////////////////////
void Page_Load(Object sender, EventArgs e)
{
	Util.do_not_cache(Response);
	Response.ContentType = "text/plain";

	var sql = new SQLString(@"
select gitcom_commit, gitcom_bug, gitcom_repository, gitap_path 
from git_commits
inner join git_affected_paths on gitap_gitcom_id = gitcom_id
where gitap_id = @id");

    int gitap_id = Convert.ToInt32(Util.sanitize_integer(Request["revpathid"]));
	sql = sql.AddParameterWithValue("id", Convert.ToString(gitap_id));

	DataRow dr = btnet.DbUtil.get_datarow(sql);

	// check if user has permission for this bug
    int permission_level = Bug.get_bug_permission_level((int)dr["gitcom_bug"], User.Identity);
	if (permission_level ==PermissionLevel.None) {
		Response.Write("You are not allowed to view this item");
		Response.End();
	}
	
	string repo = (string) dr["gitcom_repository"];
	string path = (string) dr["gitap_path"];
	string commit = Request["commit"];
	
    string text = VersionControl.git_get_file_contents(repo, commit, path);

	Response.Write(text);
}

</script>
