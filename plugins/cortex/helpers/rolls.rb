module AresMUSH
  module Cortex
    MAX_DICE_POOL = 10

    def self.roll_pool(dice, difficulty = nil, keep_extra = false)
      dice = dice.map(&:to_i)
      dice.each do |die|
        raise t('cortex.invalid_die', :die => die) if !DICE_SIZES.include?(die)
      end
      if (dice.empty? || dice.count > MAX_DICE_POOL)
        raise t('cortex.invalid_dice_pool')
      end

      results = dice.map { |die| [rand(1..die), die] }
      total, effect_die, hitch_dice, extra_die = process_results(results, difficulty, keep_extra)
      success, heroic = get_success_level(total, difficulty)

      {
        dice: dice,
        rolls: results.map { |value, die| { die: die, value: value } },
        total: total,
        effect_die: "d#{effect_die}",
        hitches: hitch_dice.map { |d| "d#{d}" },
        extra_die: extra_die,
        difficulty: difficulty,
        success: success,
        heroic: heroic
      }
    end

    def self.determine_web_roll_result(request, enactor)
      result = Cortex.parse_web_roll(request)
      return result if result[:error]

      message = Cortex.format_roll_message(enactor, result[:result], result[:pool_label])
      { message: message }
    end

    def self.parse_web_roll(request)
      dice = request.args['dice'] || []
      difficulty = request.args['difficulty']
      keep_extra = request.args['keep_extra']
      pool_label = request.args['pool_label'] || ""

      if (!dice.respond_to?(:each))
        return { error: t('cortex.invalid_dice_pool') }
      end

      difficulty = difficulty.blank? ? nil : difficulty.to_i
      keep_extra = (keep_extra == true || keep_extra.to_s == "true")

      begin
        result = Cortex.roll_pool(dice, difficulty, keep_extra)
      rescue Exception => ex
        return { error: ex.message }
      end

      { result: result, pool_label: pool_label }
    end

    def self.format_roll_message(enactor, result, pool_label)
      name = enactor ? enactor.name : t('global.system')
      rolls = result[:rolls].map { |r| "#{r[:value]}(d#{r[:die]})" }.join(" ")
      pool = pool_label.blank? ? t('cortex.dice_pool') : pool_label
      outcome = result[:success] ? (result[:heroic] ? t('cortex.heroic_success') : t('cortex.success')) : t('cortex.failure')
      diff_text = result[:difficulty] ? " vs #{result[:difficulty]}" : ""
      hitch_text = result[:hitches].any? ? " #{t('cortex.hitches')}: #{result[:hitches].join(", ")}." : ""
      extra_text = result[:extra_die] ? " #{t('cortex.extra_die')}: #{result[:extra_die]}." : ""

      "#{t('cortex.roll_prefix')} #{name} #{t('cortex.rolls')} #{pool}#{diff_text} => #{rolls} | #{t('cortex.total')} #{result[:total]}, #{t('cortex.effect')} #{result[:effect_die]}, #{outcome}.#{extra_text}#{hitch_text}"
    end

    def self.post_roll_message(message, target_type, target)
      case target_type
      when :scene
        if (target.room)
          target.room.emit message
        end
        Scenes.add_to_scene(target, message, Game.master.system_character)
      when :job
        Jobs.comment(target, Game.master.system_character, message, false)
      end
    end

    def self.process_results(results, difficulty, keep_extra)
      sorted = results.sort_by { |r| -r[0] }
      hitch_dice = results.select { |value, _die| value == 1 }.map { |_value, die| die }
      non_hitch = sorted.select { |value, _die| value != 1 }
      extra_die_value = nil

      if (keep_extra && non_hitch.count >= 3)
        total = non_hitch[0][0] + non_hitch[1][0] + non_hitch[2][0]
        extra_die_value = non_hitch[2][0]
        unused = non_hitch[3..-1] || []
        effect_die = unused.any? ? unused.map { |r| r[1] }.max : 4
      elsif (non_hitch.count >= 2)
        if (!difficulty.nil? && non_hitch.count >= 3)
          best_combo = nil
          best_effect = 0
          (0...non_hitch.count).to_a.combination(2).each do |i, j|
            combo_total = non_hitch[i][0] + non_hitch[j][0]
            next if combo_total <= difficulty
            unused_indices = (0...non_hitch.count).to_a - [i, j]
            combo_effect = unused_indices.any? ? unused_indices.map { |k| non_hitch[k][1] }.max : 4
            if (!best_combo || combo_effect > best_effect)
              best_combo = [i, j]
              best_effect = combo_effect
            end
          end

          if (best_combo)
            i, j = best_combo
            total = non_hitch[i][0] + non_hitch[j][0]
            unused_indices = (0...non_hitch.count).to_a - best_combo
            effect_die = unused_indices.any? ? unused_indices.map { |k| non_hitch[k][1] }.max : 4
          else
            total = non_hitch[0][0] + non_hitch[1][0]
            unused = non_hitch[2..-1] || []
            effect_die = unused.any? ? unused.map { |r| r[1] }.max : 4
          end
        else
          total = non_hitch[0][0] + non_hitch[1][0]
          unused = non_hitch[2..-1] || []
          effect_die = unused.any? ? unused.map { |r| r[1] }.max : 4
        end
      elsif (non_hitch.count == 1)
        total = non_hitch[0][0]
        effect_die = 4
      else
        total = 0
        effect_die = 4
      end

      [ total, effect_die, hitch_dice, extra_die_value ]
    end

    def self.get_success_level(total, difficulty)
      return [ true, false ] if difficulty.nil?
      success = total >= difficulty
      heroic = total >= (difficulty + 5) && difficulty >= 11
      [ success, heroic ]
    end
  end
end
