
q = require 'q'
EC = require('../common/exceptions').ErrorWithCause

###* 
    Connect to a relay node.
    (see bitshares_client config.json relay_account_name)
###
class RelayNode
    
    constructor:(@rpc)->
        throw new Error 'missing required parameter' unless @rpc
    
    RelayNode.ntp_offset= 0
    
    init:->
        return @init_promise if @init_promise
        @init_promise = @rpc.request('fetch_welcome_package', [{}]).then(
            (welcome)=>
                welcome = welcome.result
                for attribute in [
                    'chain_id','relay_fee_collector'
                    'relay_fee_amount','network_fee_amount'
                ]
                    value = welcome[attribute]
                    unless value or attribute is 'relay_fee_collector'
                        throw new Error "required: #{attribute}" 
                    @[attribute]=welcome[attribute]
                
                q.all([
                    @rpc.request 'get_info'
                    @rpc.request 'blockchain_get_asset', [0]
                ]).spread (
                    get_info
                    base_asset
                )=>
                    get_info = get_info.result
                    base_asset = base_asset.result
                    @base_asset_symbol = base_asset.symbol
                    unless @base_asset_symbol
                        throw new Error "required: base asset symbol"
                    #@_validate_chain_id @welcome.chain_id, @base_asset_symbol
                    (->
                        ntp_time = new Date(get_info.ntp_time).getTime()
                        utc_offset = new Date().getTime() - ntp_time
                        RelayNode.ntp_offset = utc_offset
                        if Math.abs(@utc_offset) > 5000
                            console.log "WARN: Local time and network time are off by #{ utc_offset/1000 } seconds"
                        #else console.log "INFO: ntp_offset #{ utc_offset/1000 } seconds"
                    )()
                    @initialized = yes
            
            (error)->EC.throw 'fetch_welcome_package', error
        )
    
    base_symbol:->
        throw new Error "call init()" unless @initialized
        @base_asset_symbol
    
    
    ###
    _validate_chain_id:(@chain_id, base_asset_symbol)->
        id = CHAIN_ID[base_asset_symbol]
        unless id
            console.log "WARNING: Unknown base asset symbol / chain ID: #{base_asset_symbol}, #{chain_id}"
        else
            unless id is chain_id
                throw new Error "Base asset symbol / chain ID mismatch: #{base_asset_symbol}, #{chain_id}"
    ###
    
exports.RelayNode = RelayNode