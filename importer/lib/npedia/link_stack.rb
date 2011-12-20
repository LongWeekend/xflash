module LinkStack

  def links(target_model)
    source = self
    target_table = target_model.table_name
    results = target_model.find_by_sql("
      SELECT #{target_table}.*
      FROM link_stack inner join #{target_table} ON link_stack.target_id = #{target_table}.id
      WHERE link_stack.source_id = #{source.id}
      AND link_stack.source_type = '#{source.class}'
      AND link_stack.target_type = '#{target_model.name}'
      ORDER BY created_at ASC
    ")
    results
  end

  def count_links(target_model)
    source = self
    target_table = target_model.name.pluralize
    count = target_model.find_by_sql("
      SELECT count(#{target_table}.id)
      FROM link_stack inner join #{target_table} ON link_stack.target_id = #{target_table}.id
      WHERE link_stack.source_id = #{source.id}
      AND link_stack.source_type = '#{source.class}'
      AND link_stack.target_type = '#{target_model.name}'
    ")
    count
  end

  def add_to_linkstack(source_model,source_id)
    source_id = source_model.send(:sanitize_sql, source_id)
    target_id = self.id
    source = source_model.name.to_s.downcase
    target = self.class.to_s.downcase
    sql = ActiveRecord::Base.connection()
    sql.execute("
      INSERT INTO link_stack
      (source_id, target_id, linkage, linkage_reversed, source_type, target_type, created_at) VALUES
      (#{source_id}, #{target_id}, '#{source_id}:#{target_id}', '#{target_id}:#{source_id}', '#{source}', '#{target}', NOW())
    ")
  end

  def remove_from_linkstack(target_model,target_id)
    #kill kill kill
  end

end