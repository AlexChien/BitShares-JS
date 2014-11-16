
class PublicKey

    BigInteger = require 'bigi'
    ecurve = require('ecurve')
    secp256k1 = ecurve.getCurveByName 'secp256k1'
    BigInteger = require 'bigi'
    base58 = require 'bs58'
    hash = require './hash'
    config = require '../config'
    assert = require 'assert'

    ###* @param {ecurve.Point} public key ###
    constructor: (@Q) ->
    
    PublicKey.fromBinary = (bin) ->
        PublicKey.fromBuffer new Buffer bin, 'binary'

    PublicKey.fromBuffer = (buffer) ->
        new PublicKey ecurve.Point.decodeFrom secp256k1, buffer

    toBuffer: ->
        @Q.getEncoded @Q.compressed
        
    PublicKey.fromPoint = (point) ->
        new PublicKey point

    toUncompressed: ->
        buf = @Q.getEncoded(false)
        point = ecurve.Point.decodeFrom secp256k1, buf
        PublicKey.fromPoint point
    
    ###* bts::blockchain::address (unique but not a full public key) ###
    toBlockchainAddress: ->
        #address = Address.fromBuffer(@toBuffer())
        #assert.deepEqual address.toBuffer(), h
        pub_buf = @toBuffer()
        pub_sha = hash.sha512 pub_buf
        hash.ripemd160 pub_sha
    
    ###*
    Full public key 
    {return} string
    ###
    toBtsPublic: ->
        pub_buf = @toBuffer()
        checksum = hash.ripemd160 pub_buf
        addy = Buffer.concat [pub_buf, checksum.slice 0, 4]
        config.bts_address_prefix + base58.encode addy
    
    ###*
    {param1} public_key string
    {return} PublicKey
    ###
    PublicKey.fromBtsPublic = (public_key) ->
        prefix = public_key.slice 0, config.bts_address_prefix.length
        assert.equal config.bts_address_prefix, prefix, "Expecting key to begin with #{config.bts_address_prefix}, instead got #{prefix}"
        public_key = public_key.slice config.bts_address_prefix.length
        
        public_key = new Buffer(base58.decode public_key, 'binary')
        checksum = public_key.slice -4
        public_key = public_key.slice 0, -4
        new_checksum = hash.ripemd160 public_key
        new_checksum = new_checksum.slice 0, 4
        assert.deepEqual checksum, new_checksum, 'Checksum did not match'
        PublicKey.fromBuffer public_key
    
    toBtsAddy: ->
        pub_buf = @toBuffer()
        pub_sha = hash.sha512 pub_buf
        addy = hash.ripemd160 pub_sha
        checksum = hash.ripemd160 addy
        addy = Buffer.concat [addy, checksum.slice 0, 4]
        config.bts_address_prefix + base58.encode addy
        
    toPtsAddy: ->
        pub_buf = @toBuffer()
        pub_sha = hash.sha256 pub_buf
        addy = hash.ripemd160 pub_sha
        addy = Buffer.concat [new Buffer([0x38]), addy] #version 56(decimal)
        
        checksum = hash.sha256 addy
        checksum = hash.sha256 checksum
        
        addy = Buffer.concat [addy, checksum.slice 0, 4]
        base58.encode addy
        

    ### <HEX> ###
    
    PublicKey.fromHex = (hex) ->
        PublicKey.fromBuffer new Buffer hex, 'hex'

    toHex: ->
        @toBuffer().toString 'hex'
        
    PublicKey.fromBtsPublicHex = (hex) ->
        PublicKey.fromBtsPublic new Buffer hex, 'hex'
        
    ### </HEX> ###


exports.PublicKey = PublicKey
