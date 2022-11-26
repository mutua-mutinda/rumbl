import {Presence} from "phoenix"
import Player from "./player"

let Video = {

    init(socket, element) {
        if(!element){ return }

        let playerId = element.getAttribute("data-player-id")
        let videoId = element.getAttribute("data-id")

        socket.connect() 
        
        Player.init(element.id, playerId, () => {
            this.onReady(videoId, socket)
        })
    },

    onReady(videoId, socket){
        let msgContainer = document.getElementById("msg-container")

        msgContainer.addEventListener("click", e => { 
            e.preventDefault()
            let seconds = e.target.getAttribute("data-seek") || e.target.parentNode.getAttribute("data-seek") 

            if(!seconds){ return }
            Player.seekTo(seconds)
        })

        let msgInput = document.getElementById("msg-input")
        let postButton = document.getElementById("msg-submit")

        let lastSeenId = 0
        let vidChannel = socket.channel("videos:" + videoId, () => {
            return {last_seen_id: lastSeenId}
        })

        //presence
        let userList = document.getElementById("user-list")
        let presence = new Presence(vidChannel)
        presence.onSync(() => {
            userList.innerHTML = presence.list((id, {user: user, metas: [first, ...rest]}) => {
                console.log("first", first);
                console.log("rest", rest);
                let count = rest.length + 1
                return `
                    <span class="flex items-center">
                        <span class="w-2.5 h-2.5 mr-4 bg-emerald-500 rounded-full" aria-hidden="true"></span>
                        <li class="truncate">${user.username}: (${count})</li>
                    </span>
                    `
            }).join("")
        })

        vidChannel.join()
            .receive("ok", ({annotations}) => {
                annotations.forEach( ann => this.renderAnnotation(msgContainer, ann) ) 
            })
            .receive("error", reason => console.log("join failed", reason) )

        vidChannel.on("ping", ({count}) => console.log("PING", count) )

        postButton.addEventListener("click", e => {
            let payload = {
                body: msgInput.value, 
                at: Player.getCurrentTime()
            } 
            vidChannel.push("new_annotation", payload).receive("error", e => console.log(e) ) 
            msgInput.value = ""
        })

        vidChannel.on("new_annotation", (resp) => { 
            lastSeenId = resp.id
            this.renderAnnotation(msgContainer, resp) 
        })

        vidChannel.join() 
            .receive("ok", resp => {
                let ids = resp.annotations.map(ann => ann.id) 
                if(ids.length > 0){ lastSeenId = Math.max(...ids) }
                this.scheduleMessages(msgContainer, resp.annotations) 
            })
            .receive("error", reason => console.log("join failed", reason) )
    },

    esc(str){
        let div = document.createElement("div") 
        div.appendChild(document.createTextNode(str)) 
        return div.innerHTML
    },

    renderAnnotation(msgContainer, {user, body, at}){
        let template = document.createElement("div")

        template.innerHTML = `
            <a href="#" data-seek="${this.esc(at)}" class="text-sm text-gray-700 font-medium">
                [${this.formatTime(at)}] <b>${this.esc(user.username)}</b>: ${this.esc(body)} 
            </a>`
            
            msgContainer.appendChild(template)
            msgContainer.scrollTop = msgContainer.scrollHeight
    },

    scheduleMessages(msgContainer, annotations){ 
        clearTimeout(this.scheduleTimer) 
        this.schedulerTimer = setTimeout(() => {
            let ctime = Player.getCurrentTime()
            let remaining = this.renderAtTime(annotations, ctime, msgContainer) 
            this.scheduleMessages(msgContainer, remaining)
        }, 1000) 
    },
    renderAtTime(annotations, seconds, msgContainer){
        return annotations.filter( ann => {
            if(ann.at > seconds){ 
                return true
            } 
            else {
                this.renderAnnotation(msgContainer, ann) 
                return false
            } 
        })
        },
    formatTime(at){
        let date = new Date(null) 
        date.setSeconds(at / 1000)
        return date.toISOString().substr(14, 5)
    },

}
export default Video