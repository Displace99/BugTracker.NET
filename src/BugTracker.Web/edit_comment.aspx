<%@ Page language="C#" CodeBehind="edit_comment.aspx.cs" Inherits="btnet.edit_comment" validateRequest="false" AutoEventWireup="True" %>
<%@ Register TagPrefix="uc1" Namespace="btnet.Controls" Assembly="BugTracker.Web" %>

<!--
Copyright 2002-2011 Corey Trager
Distributed under the terms of the GNU General Public License
-->
<!-- #include file = "inc.aspx" -->

<script language="C#" runat="server">

int id;
SQLString sql;


bool use_fckeditor = false;
int bugid;

void Page_Init (object sender, EventArgs e) {ViewStateUserKey = Session.SessionID;}


///////////////////////////////////////////////////////////////////////
void Page_Load(Object sender, EventArgs e)
{
    MainMenu.SelectedItem = Util.get_setting("PluralBugLabel", "bugs");
    btnet.Util.do_not_cache(Response);
    

    if (User.IsInRole(BtnetRoles.Admin)|| User.Identity.GetCanEditAndDeletePosts())
    {
        //
    }
    else
    {
        Response.Write ("You are not allowed to use this page.");
        Response.End();
    }

    titl.InnerText = btnet.Util.get_setting("AppTitle","BugTracker.NET") + " - "
        + "edit comment";

    msg.InnerText = "";

    id = Convert.ToInt32(Request["id"]);

    if (!IsPostBack)
    {
        sql = new SQLString(@"select bp_comment, bp_type,
        isnull(bp_comment_search,bp_comment) bp_comment_search,
        isnull(bp_content_type,'') bp_content_type,
        bp_bug, bp_hidden_from_external_users
        from bug_posts where bp_id = @id");
    }
    else
    {
        sql = new SQLString(@"select bp_bug, bp_type,
        isnull(bp_content_type,'') bp_content_type,
        bp_hidden_from_external_users
        from bug_posts where bp_id = @id");
    }

    sql = sql.AddParameterWithValue("id", Convert.ToString(id));
    DataRow dr = btnet.DbUtil.get_datarow(sql);

    bugid = (int) dr["bp_bug"];

    int permission_level = btnet.Bug.get_bug_permission_level(bugid, User.Identity);
    if (permission_level ==PermissionLevel.None
    || permission_level == PermissionLevel.ReadOnly
    || (string) dr["bp_type"] != "comment")
    {
        Response.Write("You are not allowed to edit this item");
        Response.End();
    }

    string content_type = (string)dr["bp_content_type"];

    if (User.Identity.GetUseFCKEditor() && content_type == "text/html" && btnet.Util.get_setting("DisableFCKEditor", "0") == "0")
    {
        use_fckeditor = true;
    }
    else
    {
        use_fckeditor = false;
    }

    if (User.Identity.GetIsExternalUser() || btnet.Util.get_setting("EnableInternalOnlyPosts","0") == "0")
    {
        internal_only.Visible = false;
        internal_only_label.Visible = false;
    }

    if (!IsPostBack)
    {
        internal_only.Checked = Convert.ToBoolean((int) dr["bp_hidden_from_external_users"]);

        if (use_fckeditor)
        {
            comment.Value = (string)dr["bp_comment"];
        }
        else
        {
            comment.Value = (string) dr["bp_comment_search"];
        }
    }
    else
    {
        on_update();
    }

}


///////////////////////////////////////////////////////////////////////
Boolean validate()
{

    Boolean good = true;

    if (comment.Value.Length == 0)
    {
        msg.InnerText = "Comment cannot be blank.";
        return false;
    }

    return good;
}

///////////////////////////////////////////////////////////////////////
void on_update()
{

    Boolean good = validate();

    if (good)
    {

        sql = new SQLString(@"update bug_posts set
                    bp_comment = @cm,
                    bp_comment_search = @cs,
                    bp_content_type = @cn,
                    bp_hidden_from_external_users = @internal
                where bp_id = @id

                select bg_short_desc from bugs where bg_id = @bugid");

        if (use_fckeditor)
        {
            string text = btnet.Util.strip_dangerous_tags(comment.Value);
            sql = sql.AddParameterWithValue("cm", text.Replace("'", "&#39;"));
            sql = sql.AddParameterWithValue("cs", btnet.Util.strip_html(comment.Value).Replace("'", "''"));
            sql = sql.AddParameterWithValue("cn", "text/html");
        }
        else
        {
            sql = sql.AddParameterWithValue("cm", HttpUtility.HtmlDecode(comment.Value).Replace("'", "''"));
            sql = sql.AddParameterWithValue("cs", comment.Value.Replace("'", "''"));
            sql = sql.AddParameterWithValue("cn", "text/plain");
        }

        sql = sql.AddParameterWithValue("id", Convert.ToString(id));
        sql = sql.AddParameterWithValue("bugid", Convert.ToString(bugid));
        sql = sql.AddParameterWithValue("internal", btnet.Util.bool_to_string(internal_only.Checked));
        DataRow dr = btnet.DbUtil.get_datarow(sql);

        // Don't send notifications for internal only comments.
        // We aren't putting them the email notifications because it that makes it
        // easier for them to accidently get forwarded to the "wrong" people...
        if (!internal_only.Checked)
        {
            btnet.Bug.send_notifications(btnet.Bug.UPDATE, bugid, User.Identity);
            btnet.WhatsNew.add_news(bugid, (string) dr["bg_short_desc"], "updated", User.Identity);
        }


        Response.Redirect ("edit_bug.aspx?id=" + Convert.ToString(bugid));

    }

}

</script>

<html>
<head>
<title id="titl" runat="server">btnet edit comment</title>
<link rel="StyleSheet" href="btnet.css" type="text/css">
<script type="text/javascript" language="JavaScript" src="scripts/jquery-1.11.1.min.js"></script>
<script type="text/javascript" language="JavaScript" src="scripts/jquery-ui.min.js"></script>
<%  if (User.Identity.GetUseFCKEditor())
    { %>
<script type="text/javascript" src="scripts/ckeditor/ckeditor.js"></script>
<% } %>

<script>

$(document).ready(do_doc_ready);

function do_doc_ready()
{

<% 
    
    if (use_fckeditor)	
    {
        Response.Write ("CKEDITOR.replace( 'comment' )");
    }
    else
    {
        Response.Write("$('textarea').resizable()");
    }

%>

}
</script>
</head>
<body>
    <uc1:MainMenu runat="server" ID="MainMenu"/>


<div class=align>
<table border=0><tr><td>

<a href=edit_bug.aspx?id=<% Response.Write(Convert.ToString(bugid));%>>back to <% Response.Write(btnet.Util.get_setting("SingularBugLabel","bug")); %></a>
<form class=frm runat="server">

    <table border=0>
        <tr>
        <td colspan=3>
        <textarea rows=16 cols=80 runat="server" class="txt resizable" id="comment"></textarea>

        <tr>
        <td colspan=3>
        <asp:checkbox runat="server" class=cb id="internal_only"/>
        <span runat="server" id="internal_only_label">Visible to internal users only</span>
        </td>
        </tr>

        <tr><td colspan=3 align=left>
        <span runat="server" class=err id="msg">&nbsp;</span>

        <tr>
        <td colspan=2 align=center>
        <input runat="server" class=btn type=submit id="sub" value="Update">

    </table>
</form>
</td></tr></table></div>
<% Response.Write(Application["custom_footer"]); %>
</body>
</html>


