module ApplicationHelper
  def rank_badge_class(rank)
    case rank
    when 1
      "bg-yellow-400 text-yellow-900 font-bold"
    when 2
      "bg-gray-300 text-gray-800 font-bold"
    when 3
      "bg-orange-400 text-orange-900 font-bold"
    else
      "bg-gray-100 text-gray-600"
    end
  end

  def rank_label(rank)
    case rank
    when 1 then t('ranks.grand_prize')
    when 2 then t('ranks.excellence')
    when 3 then t('ranks.merit')
    else t('ranks.award')
    end
  end
end
