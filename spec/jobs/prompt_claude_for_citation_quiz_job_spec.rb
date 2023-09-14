# frozen_string_literal: true

require "rails_helper"

RSpec.describe PromptClaudeForCitationQuizJob, type: :job do
  let(:instance) { described_class.new }
  let(:citation) { FactoryBot.create(:citation, citation_text: citation_text) }
  let(:citation_text) { "some text" }

  describe "#perform" do
    before { stub_const("#{described_class.name}::QUIZ_PROMPT", prompt_text) }
    context "stubbed" do
      let(:prompt_text) { "example" }
      context "success_response" do
        before { allow_any_instance_of(ClaudeIntegration).to receive(:completion_for_prompt) { "response text" } }
        it "creates a new quiz" do
          expect(citation.quizzes.count).to eq 0
          expect(Quiz.count).to eq 0
          Sidekiq::Worker.clear_all
          expect {
            instance.perform({citation_id: citation.id}.as_json)
          }.to change(Quiz, :count).by 1

          quiz = Quiz.last
          expect(quiz.citation_id).to eq citation.id
          expect(quiz.source).to eq "claude_integration"
          expect(quiz.kind).to eq "citation_quiz"
          expect(quiz.prompt_text).to eq prompt_text
          expect(quiz.input_text).to eq "response text"
          expect(QuizParseAndCreateQuestionsJob.jobs.map { |j| j["args"] }.flatten).to match_array([quiz.id])
        end
        context "redlock" do
          before do
            @lock_manager = ClaudeIntegration.new_lock
            @redlock = @lock_manager.lock(ClaudeIntegration::REDLOCK_KEY, 5000)
          end
          after { @lock_manager.unlock(@redlock) }
          it "enqueues again" do
            expect(Quiz.count).to eq 0
            Sidekiq::Worker.clear_all
            expect {
              instance.perform({citation_id: citation.id}.as_json)
            }.to change(Quiz, :count).by 0
            expect(described_class.jobs.map { |j| j["args"] }.flatten).to match_array([{citation_id: citation.id}.as_json])
          end
        end
        context "claude_admin_submission" do
          let(:prompt_text) { "some prompt, article: [ARTICLE_TEXT]" }
          let(:quiz) { FactoryBot.create(:quiz, citation: citation, source: "claude_admin_submission", prompt_text: prompt_text) }
          it "updates the quiz" do
            expect(described_class.enqueue_for_quiz?(quiz)).to be_truthy
            expect(instance.quiz_prompt_full_texts(quiz.prompt_text, citation)).to eq(["some prompt, article: some text"])
            expect(citation.reload.quizzes.count).to eq 1
            Sidekiq::Worker.clear_all
            expect {
              instance.perform({citation_id: citation.id, quiz_id: quiz.id}.as_json)
            }.to change(Quiz, :count).by 0

            expect(quiz.reload.citation_id).to eq citation.id
            expect(quiz.source).to eq "claude_admin_submission"
            expect(quiz.prompt_text).to eq prompt_text
            expect(quiz.input_text).to eq "response text"
            expect(quiz.status).to eq "pending"
            expect(QuizParseAndCreateQuestionsJob.jobs.map { |j| j["args"] }.flatten).to match_array([quiz.id])
          end
        end
      end
      context "error response" do
        let(:error_response) { '{"error": {"type": "invalid_request_error", "message": "prompt is too long: 0 tokens > 102398 maximum"}}' }
        it "creates a new quiz with the error" do
          allow_any_instance_of(ClaudeIntegration).to receive(:request_completion) { error_response }
          expect(citation.quizzes.count).to eq 0
          expect {
            instance.perform({citation_id: citation.id}.as_json)
          }.to change(Quiz, :count).by 1

          quiz = Quiz.last
          expect(quiz.citation_id).to eq citation.id
          expect(quiz.source).to eq "claude_integration"
          expect(quiz.kind).to eq "citation_quiz"
          expect(quiz.prompt_text).to eq prompt_text
          expect(quiz.input_text).to eq error_response
        end
      end
    end

    context "with citation_text" do
      let(:prompt_text) {
        "Summarize the following news article as a chronological story. Each step consists of two options, one true option based on the information from the article and one false option that contradicts the true option. It should not be possible to deduce which option at each step is true based on information provided in the previous step.After you complete that task, add a question for each step that is answered by the options. The final output should have the following format:\n\n" \
        "Step 1: {Question}\n\n" \
        "True option: \"\"\n\n" \
        "False options: \"\"\n\n" \
        "Article: [ARTICLE_TEXT]"
      }
      let(:citation_text) { "SKIP TO CONTENT\n\n\n\n\nA half-trillion dollars is starting to work its way through the US economy, remaking climate technology along the way. \n\nOne year ago, the Inflation Reduction Act was signed into law, marking the most significant action on climate change to date from the federal government. The legislation set aside hundreds of billions of dollars to support both new and existing technologies—from solar panels and heat pumps to batteries for electric vehicles—in an effort to slash costs for clean technologies and cut greenhouse gas emissions that cause climate change.\n\nRelated Story\nHere are the biggest technology wins in the breakthrough climate bill\n\nThe bill includes $369 billion in spending on climate and energy.\n\nExperts say the IRA has already begun making waves across the economy, most visibly through a steady stream of company announcements unveiling new manufacturing facilities in the US. However, the most significant effects from the legislation are still to come, as many of the programs are designed to last for a decade or longer. There are even some remaining questions about how key pieces of the bill will play out, including which projects will be eligible for heavily debated tax credits for hydrogen fuel.\n\nHere's what you need to know about where US policy on climate technology stands after one year of the Inflation Reduction Act, and what to watch for next.\n\nSo far: private companies are hopping in\n\nThe IRA includes hundreds of billions in grants, loans, and tax credits that will transform industries including energy, transportation, and agriculture. The funds will flow to technologies at several stages of development, supporting new research along with manufacturing and deployment of more established technologies.\n\nWhen details about the then-bill were first reported  in late July 2022, estimates put the total climate funding in the Inflation Reduction Act at $369 billion, making it the largest US investment in climate technology to date. An updated evaluation from the Joint Committee on Taxation in April 2023 estimated  total government investment in the IRA of  $515 billion from  2023 through  2032, though that figure doesn’t include all the law’s programs, such as consumer tax credits for electric vehicles.  \n\nMuch of the expected hundreds of billions in spending hasn’t arrived yet, and getting all that funding out the door will take a while to rev up, says Ben King, associate director of energy and climate at Rhodium Group, a policy and research nonprofit.\n\nRelated Story\nMeet the new batteries unlocking cheaper electric vehicles\n\nA planned factory marks a major milestone in the US for new batteries that enable lower-cost, longer-lasting EVs.\n\nMany of the tax credits will start to make it to businesses after they file their taxes for 2023. Some of the largest chunks of money fall into this category, including an estimated $30 billion in tax credits for companies installing clean energy projects like wind and solar farms and $60 billion in tax incentives for companies manufacturing equipment like solar panels and batteries for electric vehicles.\n\nTax credits for companies can tilt the scales, making it more favorable to do business in the US—which should spur private funding and create jobs, says Ellen Hughes-Cromwick, senior resident fellow for the climate and energy program at Third Way, a public policy think tank.\n\nThe IRA includes both tax credits that help cover part of the cost of major investments like building a new factory, as well as others that help subsidize production of products like batteries. So some provisions in the bill can help lower upfront costs, while others promise to pay for a percentage of each product a company produces. \n\nEven though funding has barely started to go out, the promise of this massive pot of money has been enough to spur a seemingly endless stream of news from companies looking to take advantage of new incentives by building or expanding manufacturing for clean energy and transportation projects in the US.\n\n“There really isn’t a day that goes by without an announcement,” Hughes-Cromwick says. \n\nSince the IRA was passed on August 16, 2022, companies have collectively announced $76 billion in investments for facilities based in the US, according to a tracker run by Jack Conness, a policy analyst at Energy Innovation.\n\nAnd while the list of planned projects includes sites that will produce components for solar panels, wind turbines, and electricity transmission equipment, the majority of announcements have been for companies that are part of the EV and battery supply chains. \n\nPart of the reason for the high concentration of battery announcements can be attributed to an additional set of tax credits for individuals purchasing electric vehicles; these credits are good for up to $7,500 toward purchase of a new EV. \n\nTo qualify for EV tax credits, vehicles have to meet requirements related to where their batteries and materials are sourced (mostly from the US or free trade agreement partners). So buyers might ultimately pay less for an EV that’s sourced mostly in the US. These restrictions are intended to push more companies to source materials and manufacture vehicles in the US. And so far, it seems to be working.\n\nRelated Story\nUS minerals industries are booming. Here’s why.\n\nDavid Turk, the Energy Department’s number two, says that recent US climate policies are creating jobs and accelerating the nation’s shift to clean energy.\n\nIn total, there have been 62 announced projects with a combined $53 billion in planned private funding just for EV and battery projects since the IRA became law, as tallied by another tracker run by Wellesley College energy researcher Jay Turner. So many multibillion-dollar battery projects have been announced across the Midwest and Southeast that a region stretching from Michigan to Georgia has earned a new nickname, the Battery Belt.\n\nMost of the projects that have been announced since the IRA was passed are still in the planning phases, though some, including a $3.5 billion joint venture between Honda and LG Energy Solution that was announced in October 2022, have already broken ground. Benefits for people in those regions are still to come, but should include well-paying jobs coming to local and regional communities, says Anand Gopal, executive director of policy research at Energy Innovation.\n\n“There is still a long way to go, but the initial signs, particularly in manufacturing, have been very good,” Gopal says.   \n\nLooking ahead: more details, and emissions cuts\n\nThe IRA is a fairly comprehensive document—the text is hundreds of pages long. But despite all those details, and the fact that it was released over a year ago, there are still questions remaining about several of the key programs in the law.\n\nOne key question just after the bill was signed, for example, was how strictly restrictions in the tax credits would be interpreted. The EV tax credits required that materials and components be sourced from either the US or free trade agreement partners, but it wasn’t immediately clear from the law’s text how the percentage of US-based materials and components would be calculated. \n\nWe’re still in the early days.\n\nEllen Hughes-Cromwick\n\nIt’s been up to the Internal Revenue Service to fill in the gaps. So far, it seems like the agency is taking a lenient approach with the clarifications it’s issued on those credits, King says. \n\nHowever, there’s still an open question about how the agency will define one more clause in the EV tax credits, which exclude vehicles that include a “foreign entity of concern” as part of the supply chain. There’s a chance this could be used to target China, which controls the vast majority of several parts of EV manufacturing, including battery material refining and component manufacturing, King says. Those restrictions, which are due to kick in starting in 2024, could limit the vehicles that are eligible for tax credits, depending on how they’re interpreted, which could result in less funding for EVs and even fewer EV customers as a result.\n\nOne of the thornier open questions of the IRA concerns a tax credit program for hydrogen.\n\nHydrogen has a wide range of potential applications for climate technology: it can be used as an alternative fuel for planes or vehicles, and it’s also used to produce chemicals like ammonia, which is used in fertilizer. Today, hydrogen is produced almost entirely using fossil fuels. But hydrogen can also be generated using electricity—and when that electricity comes from renewable sources like wind and solar, it results in “green hydrogen,” a low-emissions fuel. \n\nThe IRA includes tax incentives for green hydrogen. However, details about which projects should qualify will be critically important, Gopal says. Many electrolyzers that make hydrogen using electricity aren’t hooked up directly to a solar panel or wind turbine. Instead, they’re connected to the electrical grid, which can be powered by a mix of sources. \n\nGenerating hydrogen using electricity from a grid that’s primarily powered by fossil fuels could actually wind up increasing overall emissions. So incentives for hydrogen require “more care” than technologies like EVs that nearly always result in emissions cuts, Gopal says. \n\nRules about which hydrogen sources would be eligible for a cut of IRA funds were due to come out within one year after the IRA’s passing. But the Biden administration missed that deadline. The rules are now set to be delayed at least until October, and it could be December before there’s more clarity on this key program. \n\nMeanwhile, how all these new funding sources will translate into emissions reductions is still theoretical. Analysts and researchers estimate that the IRA could help the US reach a 40% reduction in emissions from 2005 levels by 2030. That still falls short of the target set in international agreements to reduce emissions by half, but it’s a significant improvement for the world’s largest historical emitter of greenhouse gas emissions. \n\nAll the funding in the IRA is a significant downpayment on climate action for the US, Hughes-Cromwick says. Already, private companies are plowing billions into new climate technology efforts. As more public and private funding flows into manufacturing and deployment, that can unlock lower prices and higher uptake of the technologies that can help address climate change, she adds. “We’re still in the early days … look at what we’ve seen after one year. Can you imagine what we’re going to see with 10 years of this support?”\n\nhide\n\nPOPULAR\nCovid hasn’t entirely gone away—here’s where we stand\nJessica Hamzelou\nMeta’s latest AI model is free for all \nMelissa Heikkilä\nDEEP DIVE\nCLIMATE CHANGE AND ENERGY\nThe US just invested more than $1 billion in carbon removal\n\nThe move represents a big step in the effort to suck CO2 out of the atmosphere—and slow down climate change.\n\nBy James Temple\narchive page\nThis startup has engineered a clever way to reuse waste heat from cloud computing\n\nHeata is now using these busy servers to heat water for homes.\n\nBy Luigi Avantaggiato\narchive page\nWhat’s changed in the US since the breakthrough climate bill passed a year ago?\n\nHere’s where hundreds of billions of dollars for climate technology is going.\n\nBy Casey Crownhart\narchive page\nThese moisture-sucking materials could transform air conditioning\n\nDesiccants that pull water out of the air could help cool buildings more efficiently\n\nBy Casey Crownhart\narchive page\nSTAY CONNECTED\nIllustration by Rose Wong\nGet the latest updates from\nMIT Technology Review\n\nDiscover special offers, top stories, upcoming events, and more.\n\nEnter your email\nPrivacy Policy\n\nCookie Policy\n\nWe use cookies to give you a more personalized browsing experience and analyze site traffic.See our cookie policy\n\nAccept cookies\nCookie settings" }
      it "Creates a quiz!" do
        VCR.use_cassette("create_citation_quiz_job-success") do
          expect(citation).to be_valid
          Sidekiq::Worker.clear_all
          expect {
            instance.perform({citation_id: citation.id}.as_json)
          }.to change(Quiz, :count).by 1

          quiz = Quiz.last
          expect(quiz.citation_id).to eq citation.id
          expect(quiz.source).to eq "claude_integration"
          expect(quiz.kind).to eq "citation_quiz"
          expect(quiz.prompt_text).to eq prompt_text
          expect(quiz.input_text.length).to be > 1000
          expect(QuizParseAndCreateQuestionsJob.jobs.map { |j| j["args"] }.flatten).to match_array([quiz.id])
        end
      end
      context "with a subject prompt" do
        let(:prompt_text) do
          "Summarize the following news article as a chronological story. Each step consists of two options, one true option based on the information from the article and one false option that contradicts the true option. It should not be possible to deduce which option at each step is true based on information provided in the previous step.After you complete that task, add a question for each step that is answered by the options. The final output should have the following format:\n\n" \
          "Step 1: {Question}\n\n" \
          "True option: \"\"\n\n" \
          "False options: \"\"\n\n" \
          "Article: [ARTICLE_TEXT]"
        end
        let(:subject_text) { "What is the subject of this article, in 5 words or less:\n\n[ARTICLE_TEXT]" }
        before { stub_const("#{described_class.name}::SUBJECT_PROMPT", subject_text) }
        it "creates a quiz and a subject" do
          VCR.use_cassette("create_citation_quiz_job-and_subject-success") do
            expect(citation).to be_valid
            Sidekiq::Worker.clear_all
            expect {
              instance.perform({citation_id: citation.id}.as_json)
            }.to change(Quiz, :count).by 1

            quiz = Quiz.last
            expect(quiz.citation_id).to eq citation.id
            expect(quiz.source).to eq "claude_integration"
            expect(quiz.kind).to eq "citation_quiz"
            expect(quiz.prompt_text).to eq "#{prompt_text}\n\n---\n\n#{subject_text}"
            expect(quiz.input_text.length).to be > 1000
            expect(quiz.input_text).to match(/\n\n---\n\n/)
            expect(QuizParseAndCreateQuestionsJob.jobs.map { |j| j["args"] }.flatten).to match_array([quiz.id])
          end
        end
      end
    end
  end

  describe "prompts_full_text" do
    let(:citation_text) { "Example of citation text.\n\nThat probably is pretty long.\n" }
    let(:citation) { Citation.new(citation_text: citation_text) }
    before do
      stub_const("#{described_class.name}::QUIZ_PROMPT", "Quiz:\n\n[ARTICLE_TEXT]")
      stub_const("#{described_class.name}::SUBJECT_PROMPT", "Subject:\n\n[ARTICLE_TEXT]")
    end
    let(:prompt_text) { "Quiz:\n\n[ARTICLE_TEXT]\n\n---\n\nSubject:\n\n[ARTICLE_TEXT]" }
    it "returns targets" do
      expect(instance.quiz_prompt_text(nil)).to eq prompt_text
      expect(instance.quiz_prompt_full_texts(prompt_text, citation)).to eq(["Quiz:\n\n#{citation_text.strip}", "Subject:\n\n#{citation_text.strip}"])
    end
    context "with quiz" do
      let(:quiz) { Quiz.new(prompt_text: prompt_text, citation: citation) }
      let(:prompt_text) { "Some prompt\n\n [ARTICLE_TEXT]" }
      let(:target_first) { ["Some prompt\n\n #{citation_text.strip}"] }
      it "allows multiple texts" do
        expect(instance.quiz_prompt_text(quiz)).to eq prompt_text
        expect(instance.quiz_prompt_full_texts(prompt_text, citation)).to eq target_first
      end
      context "with multiple prompts" do
        let(:prompt_text) { "Some prompt\n\n [ARTICLE_TEXT]\n\n---\nAnother Prompt\n\n[ARTICLE_TEXT]\n" }
        let(:target_both) { target_first + ["Another Prompt\n\n#{citation_text.strip}"] }
        it "allows multiple texts" do
          expect(instance.quiz_prompt_full_texts(prompt_text, citation)).to eq target_both
        end
      end
    end
  end
end
