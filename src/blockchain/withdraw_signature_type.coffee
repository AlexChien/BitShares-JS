assert = require 'assert'
ByteBuffer = require 'bytebuffer'
{fp} = require '../common/fast_parser'
{PublicKey} = require '../ecc/key_public'

###
bts::blockchain::withdraw_with_signature, (owner)(memo)
    fc::ripemd160 address owner
    optional<titan_memo> memo
    
bts::blockchain::titan_memo, (one_time_key)(encrypted_memo_data)
    public_key_type one_time_key
    vector<char> encrypted_memo_data
    
bts::blockchain::public_key_type, (key_data)
    fc::array<char,33> fc::ecc::public_key_data key_data
###
class WithdrawSignatureType

    constructor: (@owner, @one_time_key, @encrypted_memo) ->
        
    WithdrawSignatureType.fromByteBuffer= (b) ->
        owner = fp.ripemd160 b
        one_time_key = null
        encrypted_memo = null
        if fp.optional b # titan_memo
            one_time_key = fp.public_key b
            encrypted_memo = fp.variable_buffer b
        
        new WithdrawSignatureType(owner, one_time_key, encrypted_memo)
        
    appendByteBuffer: (b) ->
        fp.ripemd160 b, @owner
        if @one_time_key and @encrypted_memo
            fp.optional b, true
            fp.public_key b, @one_time_key
            fp.variable_buffer b, @encrypted_memo
            
    toJson: (o) ->
        o.owner = @owner.toString('hex')
        if @one_time_key and @encrypted_memo
            memo = o.memo = {}
            memo.one_time_key = @one_time_key.toBtsPublic()
            memo.encrypted_memo_data = @encrypted_memo.toString('hex')
            
        
    
    ### <helper_functions> ###        
    
    toBuffer: ->
        b = new ByteBuffer(ByteBuffer.DEFAULT_CAPACITY, ByteBuffer.LITTLE_ENDIAN)
        @appendByteBuffer(b)
        return new Buffer(b.copy(0, b.offset).toBinary(), 'binary')
    
    WithdrawSignatureType.fromHex= (hex) ->
        b = ByteBuffer.fromHex hex, ByteBuffer.LITTLE_ENDIAN
        return SignedTransaction.fromByteBuffer b

    toHex: () ->
        b=@toByteBuffer()
        b.toHex()
        
    ### </helper_functions> ###

exports.WithdrawSignatureType = WithdrawSignatureType
