require 'spec_helper'
include ActionDispatch::TestProcess

describe StoneDecorator do
  let(:user){FactoryGirl.create(:user)}
  let(:obj){FactoryGirl.create(:stone).decorate}
  let(:box){FactoryGirl.create(:box)}
  before{User.current = user}

  describe ".name_with_id" do
    subject{obj.name_with_id}
    it{expect(subject).to include(obj.name)}
    it{expect(subject).to include(obj.global_id)}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-cloud\"></span>")} 
  end

  describe ".path" do
    let(:me){"<span class=\"glyphicon glyphicon-cloud\"></span>me"}
    subject{obj.path}
    before { allow(obj.h).to receive(:can?).and_return(true) }
    context "box is nil" do
      before{obj.box = nil}
      it{expect(subject).to eq me} 
    end
    context "box is not nil" do
      before{obj.box = box}
      it{expect(subject).to include("<span class=\"glyphicon glyphicon-folder-close\"></span>")} 
      it{expect(subject).to include("<a href=\"/boxes/#{box.id}\">#{box.name}</a>")} 
      it{expect(subject).to include(me)} 
    end
  end

  describe ".primary_picture" do
    subject{obj.primary_picture}
    let(:data) { fixture_file_upload("/files/test_image.jpg",'image/jpeg')}
    let(:attachment_file){AttachmentFile.new(data: data)}
    subject{obj.primary_picture}
    context "attachment_files not present" do
      before{obj.attachment_files.clear}
      it{expect(subject).to be_blank}
    end
    context "attachment_files present" do
      before do
        attachment_file.save
        obj.attachment_files << attachment_file
      end
      it{expect(subject).to match("<img.* />")}
      it{expect(subject).to include(("alt=\"#{h.image_alt(attachment_file.data_file_name)}\" "))}
      it{expect(subject).to include(("src=\"#{attachment_file.path}\""))}
      it{expect(subject).to include("height=\"250\"")}
      it{expect(subject).to include("width=\"250\"")}
    end
    context "width,height" do
      subject{obj.primary_picture(width: width,height: height)}
      let(:width){100}
      let(:height){200}
      before do
        attachment_file.save
        obj.attachment_files << attachment_file
      end
      it{expect(subject).to include("height=\"#{height}\"")}
      it{expect(subject).to include("width=\"#{width}\"")}
    end
  end

  describe ".attachment_file_image_link" do
    subject{obj.attachment_file_image_link(attachment_file)}
    let(:attachment_file){AttachmentFile.new(data: data)}
    context "has image" do
      let(:data) { fixture_file_upload("/files/test_image.jpg",'image/jpeg')}
      before{attachment_file.save}
      it{expect(subject).to match("<a href=\"/attachment_files/#{attachment_file.id}\">.*</a>")}
      it{expect(subject).to match("<img.* />")}
      it{expect(subject).to include(("alt=\"#{h.image_alt(attachment_file.data_file_name)}\" "))}
      it{expect(subject).to include("src=\"#{attachment_file.path}\"")}
      it{expect(subject).to include("height=\"40\"")}
      it{expect(subject).to include("width=\"40\"")}

    end
    context "has no image" do
      let(:data) { fixture_file_upload("/files/test_pdf.pdf",'application/pdf')}
      before{attachment_file.save}
      it{expect(subject).to match("<a href=\"/attachment_files/#{attachment_file.id}\">.*</a>")} 
      it{expect(subject).to include("<span class=\"glyphicon glyphicon-file\"></span>")} 
    end
    context "width,height" do
      let(:data) { fixture_file_upload("/files/test_image.jpg",'image/jpeg')}
      before{attachment_file.save}
      subject{obj.attachment_file_image_link(attachment_file,width:10,height:20)}
      it{expect(subject).to include("width=\"10\"")}
      it{expect(subject).to include("height=\"20\"")}
    end
  end

  describe ".family_tree" do
    subject{obj.family_tree}
    before { allow(obj.h).to receive(:can?).and_return(true) }
    it{expect(subject).to match("<div class=\"tree-node\" data-depth=\"1\">.*</div>")}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-cloud\"></span>")} 
    it{expect(subject).to match("<a href=\"/stones/#{obj.id}\">.*</a>")}
    it{expect(subject).to include("<strong>#{obj.name}</strong>")} 
  end

  describe ".tree_node" do
    subject{obj.tree_node}
    before { allow(obj.h).to receive(:can?).and_return(true) }
    let(:child){FactoryGirl.create(:stone)}
    let(:analysis){FactoryGirl.create(:analysis)}
    let(:bib){FactoryGirl.create(:bib)}
    let(:attachment_file){FactoryGirl.create(:attachment_file)}
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-cloud\"></span>")} 
    it{expect(subject).to include("#{obj.name}")} 
    before do
      obj.children << child
      obj.analyses << analysis
      obj.bibs << bib 
      obj.attachment_files << attachment_file 
    end
    it{expect(subject).to include("<span class=\"glyphicon glyphicon-cloud\"></span><span>#{obj.children.count}</span>")} 
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

  describe "children_count" do
    subject{obj.children_count}
    let(:icon){"cloud"}
    let(:count){obj.children.count}
    context "count zero" do
      before{obj.children.clear}
      it{expect(subject).to be_blank} 
    end
    context "count zero" do
      let(:child){FactoryGirl.create(:stone)}
      before{obj.children << child}
      it{expect(subject).to include("<span>#{count}</span>")} 
      it{expect(subject).to include("<span>#{obj.children.count}</span>")} 
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
    context "count zero" do
      let(:analysis){FactoryGirl.create(:analysis)}
      before{obj.analyses << analysis}
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
    context "count zero" do
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

  describe ".to_tex" do
    subject{obj.to_tex}
    let(:child_name){"child_name"}
    let(:child){FactoryGirl.create(:stone,name: child_name)}
    before{obj.children << child}
    it{expect(subject).to include(obj.name)}
    it{expect(subject).to include(obj.global_id)}
    it{expect(subject).to include(child.name)}
    it{expect(subject).to include(child.physical_form.name)}
    it{expect(subject).to include(child.quantity.to_s)}
    it{expect(subject).to include(child.global_id)}
  end
  
end