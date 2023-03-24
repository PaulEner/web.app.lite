class PonctualScripts::ResetAdminDashboard
  def initialize; end

  def execute(reset_type, force=false)
    @force = force

    case reset_type
      when "grouping"
        reset_grouping
      when "lad"
        reset_lad
      end
  end

  private

  def reset_grouping
    pack_names = TempDocument.where(state: 'bundle_needed').collect(&:temp_pack).collect(&:name).uniq

    staffings = []
    pack_names.each do |p_name|
      name = p_name.split('%')[1].presence || p_name
      name = name.gsub(' all', '')
      sf = StaffingFlow.where("params LIKE '%#{name}%'").last
      staffings << sf if sf
    end

    staffings.each{ |st| st.update(state: "ready")  if @force || !st.processing? }

    { pack_names: pack_names, staffings_size: staffings.size}
  end

  def reset_lad
    pieces = Pack::Piece.where(pre_assignment_state: "adr")
    pieces.update_all(pre_assignment_state: "waiting")

    { count_pieces: pieces.size }
  end
end

