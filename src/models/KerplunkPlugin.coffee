###
# KerplunkPlugin schema
###

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  KerplunkPluginSchema = new Schema
    name:
      type: String
      required: true
      index:
        unique: true
    displayName:
      type: String
    description:
      type: String
    tag: [
      type: String
      index: true
    ]
    kerplunk:
      type: Object
    data:
      type: String
    moderated:
      type: Boolean
      default: -> false
    updatedAt:
      type: Date
      default: Date.now
    createdAt:
      type: Date
      default: Date.now

  mongoose.model 'KerplunkPlugin', KerplunkPluginSchema
