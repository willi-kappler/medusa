require 'spec_helper'

describe BoxDecorator do
  let(:user){FactoryGirl.create(:user)}
  let(:obj){FactoryGirl.create(:box).decorate}
  before{User.current = user}

  describe ".to_json", :current => true do
    subject{obj.to_json}
    it{ expect(subject).to include "global_id" }
  end

  describe ".name_with_id" do
    subject{obj.name_with_id}
    it{expect(subject).to include(obj.name)}
    it{expect(subject).to include(obj.global_id)}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-folder-close\"></span>")}
  end

  describe ".primary_picture" do
    let(:attachment_file){ FactoryGirl.create(:attachment_file) }
    let(:picture) { obj.primary_picture(width: width, height: height) }
    let(:capybara) { Capybara.string(picture) }
    let(:body) { capybara.find("body") }
    let(:img) { body.find("img") }
    let(:width) { 250 }
    let(:height) { 250 }
    before { obj.attachment_files = [attachment_file] }
    it { expect(body).to have_css("img") }
    it { expect(img["src"]).to eq attachment_file.path }
    context "width rate greater than height rate" do
      let(:width) { 100 }
      it { expect(img["width"]).to eq width.to_s }
      it { expect(img["height"]).to be_blank }
    end
    context "width rate eq height rate" do
      it { expect(img["width"]).to eq width.to_s }
      it { expect(img["height"]).to be_blank }
    end
    context "width rate less than height rate" do
      let(:height) { 100 }
      it { expect(img["width"]).to be_blank }
      it { expect(img["height"]).to eq height.to_s }
    end
  end

  describe ".family_tree" do
    subject{obj.family_tree}
    let(:child){FactoryGirl.create(:box)}
    let(:specimen){FactoryGirl.create(:specimen)}
    before do
      allow(obj.h).to receive(:can?).and_return(true)
      obj.children << child
    end
    it{expect(subject).to match("<div class=\"tree-node\" data-depth=\"1\">.*</div>")}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-folder-close\"></span>")}
    it{expect(subject).to match("<a href=\"/boxes/#{obj.id}\">.*</a>")}
    it{expect(subject).to include("<strong>#{obj.name}</strong>")}
    it{expect(subject).to match("<div class=\"tree-node\" data-depth=\"2\">.*</div>")}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-folder-close\"></span>")}
    it{expect(subject).to match("<a href=\"/boxes/#{child.id}\">.*</a>")}
    it{expect(subject).to include("#{child.name}")}
    context "box linked specimen" do
      before { obj.specimens << specimen }
      it{expect(subject).to include("<span class=\"glyphicon glyphicon-cloud\"></span>")}
      it{expect(subject).to match("<a href=\"/specimens/#{specimen.id}\">.*</a>")}
      it{expect(subject).to include("#{specimen.name}")}
    end
    context "box not link specimen" do
      it{expect(subject).not_to include("#{specimen.name}")}
    end
  end

  describe ".tree_node", :current => true do
    subject{obj.tree_node}
    let(:specimen){FactoryGirl.create(:specimen)}
    let(:child){FactoryGirl.create(:box)}
    let(:analysis){FactoryGirl.create(:analysis)}
    let(:bib){FactoryGirl.create(:bib)}
    let(:attachment_file){FactoryGirl.create(:attachment_file)}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-folder-close\"></span>")}
    it{expect(subject).to include("#{obj.name}")}
    before do
      allow(obj.h).to receive(:can?).and_return(true)
      specimen.analyses << analysis
      obj.specimens << specimen
      obj.children << child
      obj.bibs << bib
      obj.attachment_files << attachment_file
    end
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-cloud\"></span><span>#{obj.specimens.count}</span>")}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-folder-close\"></span><span>#{obj.specimens.count}</span>")}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-stats\"></span><span>#{obj.analyses.count}</span>")}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-book\"></span><span>#{obj.bibs.count}</span>")}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-file\"></span><span>#{obj.attachment_files.count}</span>")}
    context "current" do
      subject{obj.tree_node(true)}
      it{expect(subject).to match("<strong>.*</strong>")}
    end
    context "not current" do
      subject{obj.tree_node(false)}
      it{expect(subject).not_to match("<strong>.*</strong>")}
    end
  end

  describe "specimens_count" do
    subject{obj.specimens_count}
    let(:icon){"cloud"}
    let(:count){obj.specimens.count}
    context "count zero" do
      before{obj.specimens.clear}
      it{expect(subject).to be_blank}
    end
    context "count zero" do
      let(:specimen){FactoryGirl.create(:specimen)}
      before{obj.specimens << specimen}
      it{expect(subject).to include("<span>#{count}</span>")}
      it{expect(subject).to include("<span class=\"glyphicon glyphicon-#{icon}\"></span>")}
    end
  end

  describe "boxes_count" do
    subject{obj.boxes_count}
    let(:icon){"folder-close"}
    let(:count){obj.children.count}
    context "count zero" do
      before{obj.children.clear}
      it{expect(subject).to be_blank}
    end
    context "count not zero" do
      let(:child){FactoryGirl.create(:box)}
      before{obj.children << child}
      it{expect(subject).to include("<span>#{count}</span>")}
      it{expect(subject).to include("<span class=\"glyphicon glyphicon-#{icon}\"></span>")}
    end
  end

  describe "analyses_count" do
    subject{obj.analyses_count}
    let(:icon){"stats"}
    let(:count){obj.analyses.count}
    context "count zero" do
      before{obj.analyses.clear}
      it{expect(subject).to be_blank}
    end
    context "count not zero" do
      let(:specimen){FactoryGirl.create(:specimen)}
      let(:analysis){FactoryGirl.create(:analysis)}
      before{specimen.analyses  << analysis}
      before{obj.specimens << specimen}
      it{expect(subject).to include("<span>#{count}</span>")}
      it{expect(subject).to include("<span class=\"glyphicon glyphicon-#{icon}\"></span>")}
    end
  end

  describe "bibs_count" do
    subject{obj.bibs_count}
    let(:icon){"book"}
    let(:count){obj.bibs.count}
    context "count zero" do
      before{obj.bibs.clear}
      it{expect(subject).to be_blank}
    end
    context "count not zero" do
      let(:bib){FactoryGirl.create(:bib)}
      before{obj.bibs << bib}
      it{expect(subject).to include("<span>#{count}</span>")}
      it{expect(subject).to include("<span class=\"glyphicon glyphicon-#{icon}\"></span>")}
    end
  end

  describe "files_count" do
    subject{obj.files_count}
    let(:icon){"file"}
    let(:count){obj.attachment_files.count}
    context "count zero" do
      before{obj.attachment_files.clear}
      it{expect(subject).to be_blank}
    end
    context "count zero" do
      let(:attachment_file){FactoryGirl.create(:attachment_file)}
      before{obj.attachment_files << attachment_file}
      it{expect(subject).to include("<span>#{count}</span>")}
      it{expect(subject).to include("<span class=\"glyphicon glyphicon-#{icon}\"></span>")}
    end
  end

  describe ".boxed_specimens" do
    subject{obj.boxed_specimens}
    it{expect(subject).to eq(Specimen.includes(:record_property, :user, :group, :physical_form).where(box_id: obj.id))} 
  end

  describe ".boxed_boxes" do
    subject{obj.boxed_boxes}
    it{expect(subject).to eq(Box.includes(:record_property, :user, :group).where(parent_id: obj.id))} 
  end

  describe ".to_tex" do
    subject { obj.to_tex(alias_specimen) }
    before { obj.specimens << specimen }
    let(:alias_specimen) { "specimen" }
    let(:specimen) { FactoryGirl.create(:specimen, name: "name_1", box_id: obj.id) }
    let(:time_now) { Time.now.to_date }
    it { expect(subject).to eq "%------------\nThe sample names and ID of each mounted materials are listed in Table \\ref{mount:materials}.\n%------------\n\\begin{footnotesize}\n\\begin{table}\n\\caption{#{alias_specimen.pluralize.capitalize} mounted on #{obj.name} (#{obj.global_id}) as of #{time_now}.}\n\\begin{center}\n\\begin{tabular}{lll}\n\\hline\n#{alias_specimen} name\t&\tID\t&\tremark\\\\\n\\hline\nname_1\t&\t#{specimen.global_id}\t&\t\\\\\n\\hline\n\\end{tabular}\n\\end{center}\n\\label{mount:materials}\n\\end{table}\n\\end{footnotesize}\n%------------" }
  end

end
