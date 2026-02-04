module AresMUSH
  module Cortex
    class CortexAddJobRollRequestHandler
      def handle(request)
        job = Job[request.args['id']]
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        if (!job)
          return { error: t('webportal.not_found') }
        end

        if (!Jobs.can_access_job?(enactor, job, true))
          return { error: t('jobs.cant_view_job') }
        end

        if (!job.is_open?)
          return { error: t('jobs.job_already_closed') }
        end

        result = Cortex.determine_web_roll_result(request, enactor)
        return result if result[:error]

        Cortex.post_roll_message(result[:message], :job, job)

        {
        }
      end
    end
  end
end
