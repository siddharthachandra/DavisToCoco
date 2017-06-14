%Create coco format json dataset from images, and png segmentation masks
%Dependencies: jsonlab (https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files)
%Author: Siddhartha Chandra (siddhartha.chandra@inria.fr)
VISUALIZE = true;
ROOTDIR = '/Users/sidc/Davis';
DATADIR = fullfile(ROOTDIR,'data');
colors_ = {'y','m','c','r','g','b','w','k'};
sets_ = {'trainval','testdev'};
n = numel(sets_);
all_labels = [];

imgid = 0;
videoid = 0;
annid = 0;
for setid_ = 1 : n
    set_ = sets_{setid_};
    imagesets_ = dir(fullfile(DATADIR,set_,'ImageSets/2017','*.txt'));
    subsets_ = {imagesets_.name};
    ns = numel(subsets_);
    for subsetid_ = 1 : ns

        % create datastructure for dataset
        % field: images (id, file_name,width,height,seg_file_name)
        % field: type ('instances')
        % field: categories (supercategory, id, name)
        % field: annotations (segmentation, area, iscrowd, image_id, bbox, category_id)

        davis = struct;
        davis.type = 'instances';
        davis.annotations = {};
        davis.images = {};
        davis.categories = {};
        davis.categories{1} = struct;
        davis.categories{1}.supercategory = 'salient';
        davis.categories{1}.name = 'salient';
        davis.categories{1}.id = 1;


        list_ = textread(fullfile(DATADIR,set_,'ImageSets/2017',subsets_{subsetid_}),'%s');
        nl = numel(list_);
        for seqid_ = 1 : nl
            videoid = videoid + 1;
            fprintf('showing set %d/%d subset %d/%d seq %d/%d %s\n',setid_,n,subsetid_,ns,seqid_,nl);
            rgb_ = dir(fullfile(DATADIR,set_,'JPEGImages/480p',list_{seqid_},'*.jpg'));
            rgb_ = {rgb_.name};
            ni = numel(rgb_);
            for i = 1 : ni
                imgid = imgid + 1;
                imgpath_ = fullfile(DATADIR,set_,'JPEGImages/480p',list_{seqid_},rgb_{i});
                segpath_ = fullfile(DATADIR,set_,'Annotations/480p',list_{seqid_},regexprep(rgb_{i},'.jpg','.png'));
                im = imread(imgpath_);
                seg= imread(segpath_);
                [r_,c_] = size(seg);
                davis.images{imgid} = struct;
                davis.images{imgid}.file_name = rgb_{i};
                davis.images{imgid}.seg_file_name = regexprep(rgb_{i},'.jpg','.png');
                davis.images{imgid}.width = c_;
                davis.images{imgid}.height = r_;
                davis.images{imgid}.id = imgid;
                davis.images{imgid}.video_id = videoid;
                unique_instances_ = unique(seg);
                if VISUALIZE
                    subplot(2,2,1); imshow(im);
                    subplot(2,2,2); imagesc(seg); axis off; axis image; colormap(jet(30)); drawnow;
                    subplot(2,2,3); imshow(im); hold on;
                    subplot(2,2,4); imshow(im); hold on;
                end
                for inst = unique_instances_'
                    if inst == 0 %ignore background.
                        continue;
                    end
                    mask_ = seg==inst;
                    area_ = sum(mask_(:));
                    [B_,L_,N_,A_] = bwboundaries(mask_);
                    B_ = B_(1:N_); %the rest are holes. We don't know what to do with the holes at this point!
                    %get BBOX
                    allpoints_ = cat(1,B_{:});
                    minyx_ = min(allpoints_);
                    maxyx_ = max(allpoints_);
                    bbox.x1 = minyx_(2);
                    bbox.y1 = minyx_(1);
                    bbox.x2 = maxyx_(2);
                    bbox.y2 = maxyx_(1);
                    bbox.w = bbox.x2 - bbox.x1;
                    bbox.h = bbox.y2 - bbox.y1;
                    BBOX = [bbox.x1 bbox.y1 bbox.w bbox.h];
                    if VISUALIZE % some visualization
                        x__ = [minyx_(2) maxyx_(2) maxyx_(2) minyx_(2) minyx_(2)];
                        y__ = [minyx_(1) minyx_(1) maxyx_(1) maxyx_(1) minyx_(1)];
                        colorid_ = rem(inst,numel(colors_));
                        color_ = colors_{colorid_};
                        subplot(2,2,3); hold on; plot(x__,y__,color_,'Linewidth',3);
                    end
                    % get Polygons
                    segmentations_ = cell(1,N_);
                    for polyid = 1 : N_
                        thisPoly_ = B_{polyid};
                        thisPoly_ = [thisPoly_(:,2) thisPoly_(:,1)];
                        if VISUALIZE % some visualization
                            colorid_ = rem(inst,numel(colors_));
                            color_ = colors_{colorid_};
                            subplot(2,2,4); hold on; plot(thisPoly_(:,1),thisPoly_(:,2),color_,'Linewidth',3);
                        end
                        thisPoly_ = reshape(thisPoly_,1,[]);
                        segmentations_{polyid} = thisPoly_;

                    end
                    annid = annid + 1;
                    davis.annotations{annid} = struct;
                    davis.annotations{annid}.segmentation = segmentations_;
                    davis.annotations{annid}.area = area_;
                    davis.annotations{annid}.iscrowd = 0;
                    davis.annotations{annid}.image_id = imgid;
                    davis.annotations{annid}.bbox = BBOX;
                    davis.annotations{annid}.category_id = 1;
                    davis.annotations{annid}.id = annid;
                end
                drawnow;
                uu = unique(seg);
                all_labels = unique([all_labels; uu]);
            end
            fprintf('label_set %s\n',num2str(all_labels'));

        end
        savejson('',davis,(regexprep(subsets_{subsetid_},'.txt','.json')));
    end
end
