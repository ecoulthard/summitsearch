class ForumUserAudit
  def self.report(users = User.all)
    nonblank = users.where("username IS NOT NULL AND btrim(username) <> ?", "")
    {
      users: users.count,
      null_usernames: users.where(username: nil).count,
      blank_usernames: users.where("username IS NOT NULL AND btrim(username) = ?", "").count,
      whitespace_usernames: users.where("username <> btrim(username)").count,
      duplicate_case_insensitive_groups: nonblank.group(Arel.sql("lower(btrim(username))")).having("count(*) > 1").count.size
    }
  end
end
