module CollectionsHelper
  
  # Generates a draggable, pop-up div which contains the add-to-collection form 
  def collection_link(item)
    if item.class == Chapter
      item = item.work
    end
    if logged_in?
      if item.class == Work
        link_to ts("Add To Collection"), new_work_collection_item_path(item), remote: true
      elsif item.class == Bookmark
        link_to ts("Add To Collection"), new_bookmark_collection_item_path(item)
      end
    end
  end
  
  # show a section if it's not empty or if the parent collection has it
  def show_collection_section(collection, section)
    if ["intro", "faq", "rules"].include?(section) # just a check that we're not using a bogus section string
      !collection.collection_profile.send(section).blank? || collection.parent && !collection.parent.collection_profile.send(section).blank?
    end
  end

  # show collection preface if at least one section of the profile (or the parent collection's profile) is not empty
  def show_collection_preface(collection)
    show_collection_section(collection, "intro") || show_collection_section(collection, "faq") || show_collection_section(collection, "rules")
  end
  
  # show navigation to relevant sections of the profile if needed
  def show_collection_profile_navigation(collection, section)
    ["intro", "faq", "rules"].each do |s|
      if show_collection_section(collection, s) && s != section
        return true # if at least one other section than the current one is not blank, we need the navigation; break out of the each...do
      end
    end
    return false # if it passed through all tests above and not found a match, then we don't need the navigation
  end
  
  def challenge_class_name(collection)
    collection.challenge.class.name.demodulize.tableize.singularize
  end
  
  def show_collections_data(collections)
    collections.collect { |coll| link_to coll.title, collection_path(coll) }.join(ArchiveConfig.DELIMITER_FOR_OUTPUT).html_safe
  end

  def challenge_assignment_byline(assignment)
    if assignment.offer_signup && assignment.offer_signup.pseud
      assignment.offer_signup.pseud.byline 
    elsif assignment.pinch_hitter 
      assignment.pinch_hitter.byline + "* (pinch hitter)" 
    else
      ""
    end
  end
  
  def challenge_assignment_email(assignment)
    if assignment.offer_signup && assignment.offer_signup.pseud
      user = assignment.offer_signup.pseud.user
    elsif assignment.pinch_hitter 
      user = assignment.pinch_hitter.user
    else
      user = nil
    end
    if user
      mailto_link user, subject: "[#{(@collection.title)}] Message from Collection Maintainer"
    end
  end

  def collection_item_display_title(collection_item)
    item = collection_item.item
    item_type = collection_item.item_type
    if item_type == 'Bookmark' && item.present? && item.bookmarkable.present?
      # .html_safe is necessary for titles with ampersands etc when inside ts()
      ts('Bookmark for %{title}', title: item.bookmarkable.title).html_safe
    elsif item_type == 'Bookmark'
      ts('Bookmark of deleted item')
    elsif item_type == 'Work' && item.posted?
      item.title
    elsif item_type == 'Work' && !item.posted?
      ts('%{title} (Draft)', title: item.title).html_safe
    # Prevent 500 error if collection_item is not destroyed when collection_item.item is
    else
      ts('Deleted or unknown item')
    end
  end

  def collection_item_approval_options_label(actor:, item_type:)
    item_type = item_type.downcase
    actor = actor.downcase

    case actor
    when "user"
      t("collections_helper.collection_item_approval_options_label.user.#{item_type}")
    when "collection"
      t("collections_helper.collection_item_approval_options_label.collection")
    end
  end

  # i18n-tasks-use t('collections_helper.collection_item_approval_options.collection.approved')
  # i18n-tasks-use t('collections_helper.collection_item_approval_options.collection.rejected')
  # i18n-tasks-use t('collections_helper.collection_item_approval_options.collection.unreviewed')
  # i18n-tasks-use t('collections_helper.collection_item_approval_options.user.bookmark.approved')
  # i18n-tasks-use t('collections_helper.collection_item_approval_options.user.bookmark.rejected')
  # i18n-tasks-use t('collections_helper.collection_item_approval_options.user.bookmark.unreviewed')
  # i18n-tasks-use t('collections_helper.collection_item_approval_options.user.work.approved')
  # i18n-tasks-use t('collections_helper.collection_item_approval_options.user.work.rejected')
  # i18n-tasks-use t('collections_helper.collection_item_approval_options.user.work.unreviewed')
  def collection_item_approval_options(actor:, item_type:)
    item_type = item_type.downcase
    actor = actor.downcase

    key = case actor
          when "user"
            "collections_helper.collection_item_approval_options.user.#{item_type}"
          when "collection"
            "collections_helper.collection_item_approval_options.collection"
          end

    [
      [t("#{key}.unreviewed"), :unreviewed],
      [t("#{key}.approved"), :approved],
      [t("#{key}.rejected"), :rejected]
    ]
  end

  # Fetches the icon URL for the given collection, using the standard (100x100) variant.
  def standard_icon_url(collection)
    return "/images/skins/iconsets/default/icon_collection.png" unless collection.icon.attached?

    rails_blob_url(collection.icon.variant(:standard))
  end

  # Wraps the collection's standard_icon_url in an image tag
  def collection_icon_display(collection)
    image_tag(standard_icon_url(collection), size: "100x100", alt: collection.icon_alt_text, class: "icon", skip_pipeline: true)
  end
end
