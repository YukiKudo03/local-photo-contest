# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry
  before_action :set_comment, only: [ :destroy ]
  before_action :authorize_comment!, only: [ :destroy ]

  def create
    @comment = @entry.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.html { redirect_to entry_path(@entry), notice: "コメントを投稿しました。" }
        format.turbo_stream
      else
        format.html { redirect_to entry_path(@entry), alert: @comment.errors.full_messages.join(", ") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_form", partial: "comments/form", locals: { entry: @entry, comment: @comment }) }
      end
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to entry_path(@entry), notice: "コメントを削除しました。" }
      format.turbo_stream
    end
  end

  private

  def set_entry
    @entry = Entry.find(params[:entry_id])
  end

  def set_comment
    @comment = @entry.comments.find(params[:id])
  end

  def authorize_comment!
    return if @comment.user == current_user || @entry.user == current_user

    redirect_to entry_path(@entry), alert: "この操作を行う権限がありません。"
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
