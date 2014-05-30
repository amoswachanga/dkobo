define 'cs!xlform/view.row', [
        'backbone',
        'jquery',
        'cs!xlform/view.rowSelector',
        'cs!xlform/model.row',
        'cs!xlform/view.templates',
        'cs!xlform/view.utils',
        'cs!xlform/view.choices',
        'cs!xlform/view.rowDetail',
        ], (
            Backbone,
            $,
            $rowSelector,
            $row,
            $viewTemplates,
            $viewUtils,
            $viewChoices,
            $viewRowDetail,
            )->
  class BaseRowView extends Backbone.View
    tagName: "li"
    className: "xlf-row-view survey__row"
    events:
     "click .js-expand-row-selector": "expandRowSelector"
     "drop": "drop"
     "click .js-add-to-question-library": "add_row_to_question_library"

    initialize: (opts)->
      @options = opts
      typeDetail = @model.get("type")
      @$el.attr("data-row-id", @model.cid)
      @ngScope = opts.ngScope
      # @model.on "change", @render, @
      # typeDetail.on "change:value", _.bind(@render, @)
      # typeDetail.on "change:listName", _.bind(@render, @)
      @surveyView = @options.surveyView
      @model.on "detail-change", (key, value, ctxt)=>
        customEventName = "row-detail-change-#{key}"
        @$(".on-#{customEventName}").trigger(customEventName, key, value, ctxt)

    drop: (evt, index)->
      @$el.trigger("update-sort", [@model, index])

    getApp: ->
      @surveyView.getApp()

    expandRowSelector: ->
      new $rowSelector.RowSelector(el: @$el.find(".expanding-spacer-between-rows").get(0), ngScope: @ngScope, spawnedFromView: @).expand()

    render: ->
      if @model instanceof $row.RowError
        @_renderError()
      else
        @_renderRow()
      @$el.data("row-index", @model.getSurvey().rows.indexOf @model)
      @
    _renderError: ->
      @$el.addClass("xlf-row-view-error")
      atts = $viewUtils.cleanStringify(@model.attributes)
      @$el.html $viewTemplates.$$render('row.rowErrorView', atts)
      @
    _renderRow: ->
      @$el.html $viewTemplates.$$render('row.xlfRowView')
      @$card = @$el.find('.card')
      if 'getList' of @model and (cl = @model.getList())
        @$card.addClass('card--selectquestion')
        @listView = new $viewChoices.ListView(model: cl, rowView: @).render()

      @rowExtras = @$(".row-extras")
      @rowExtrasSummary = @$(".row-extras-summary")
      for [key, val] in @model.attributesArray()
        new $viewRowDetail.DetailView(model: val, rowView: @).renderInRowView(@)
      @

    add_row_to_question_library: (evt) ->
      evt.stopPropagation()
      @ngScope.add_row_to_question_library @model

  class GroupView extends BaseRowView
    className: "xlf-row-view survey__row survey__row--group"
    events:
      "click .js-delete-group": "deleteGroup"
      "click .js-expand-row-selector": "expandRowSelector"
    initialize: (opts)->
      @options = opts
      @_shrunk = !!opts.shrunk
      @$el.attr("data-row-id", @model.cid)
      @surveyView = @options.surveyView
    deleteGroup: (evt)->
      if confirm('Are you sure you want to delete this group? All questions will be lost')
        @model.detach()
        @$el.remove()
      evt.preventDefault()

    render: ->
      @$el.html $viewTemplates.row.groupView(@model)
      @$rows = @$('.group__rows').eq(0)
      @rowExtras = @$('.group__settings').eq(0)

      @model.rows.each (row)=>
        @getApp().ensureElInView(row, @, @$rows).render()
      @$el.data("row-index", @model.getSurvey().rows.indexOf @model)

      for [key, val] in @model.attributesArray()
        new $viewRowDetail.DetailView(model: val, rowView: @).renderInRowView(@)
      @

  class RowView extends BaseRowView

  RowView: RowView
  GroupView: GroupView
