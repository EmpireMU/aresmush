module AresMUSH
  module Cortex
    class CortexAddSceneRollRequestHandler
      def handle(request)
        scene = Scene[request.args['id']]
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        if (!scene)
          return { error: t('webportal.not_found') }
        end

        if (!Scenes.can_read_scene?(enactor, scene))
          return { error: t('scenes.access_not_allowed') }
        end

        if (scene.completed)
          return { error: t('scenes.scene_already_completed') }
        end

        result = Cortex.determine_web_roll_result(request, enactor)
        return result if result[:error]

        Cortex.post_roll_message(result[:message], :scene, scene)

        {
        }
      end
    end
  end
end
