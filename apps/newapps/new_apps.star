"""
Applet: New Apps
Summary: Lists new Tidbyt apps
Description: Lists new Tidbyt apps within the last week.
Author: rs7q5
"""
#new_apps.star
#Created 20230119 RIS
#Last Modified 20230210 RIS

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

BASE_URL = "https://api.tidbyt.com/v0/apps"
FONT = "tom-thumb"

def main(config):
    #get old list of apps
    old_data = cache.get("old_apps")
    force_current_list = False
    if old_data != None:
        print("Hit! Using cached old app list data.")
        old_list = json.decode(old_data)
        force_current_list = False
    else:
        print("Miss! Refreshing old app list data.")
        old_list = get_apps()
        if old_list != None:
            cache.set("old_apps", json.encode(old_list), ttl_seconds = 604800)  #refresh old list once a week
            force_current_list = True

    #get current list of apps
    current_data = cache.get("current_apps")
    if current_data != None and force_current_list == False:
        #use old data if one did not just refresh the old list or the other data has not expired
        print("Hit! Using cached current app list data.")
        current_list = json.decode(current_data)
    else:
        print("Miss! Refreshing current app list data.")
        current_list = get_apps()
        if current_list != None:
            cache.set("current_apps", json.encode(current_list), ttl_seconds = 1800)  #refresh current list every 30 minutes

    #get final frame
    if old_list == None or current_list == None:
        final_list = ["Error getting list of apps!!!!"]
    else:
        #compare the current app list and old app list to see if there are any new apps
        new_apps = []
        for app_id in current_list.keys():
            app_name = old_list.get(app_id, None)  #check if the app is in the old list
            if app_name == None:
                new_apps.append(current_list[app_id])  #add app to list of new apps if it is not in the old list

        #get output based on if there are new apps or not
        if new_apps == []:
            if config.bool("apps_only", True):
                return []  #don't display in rotation if there are no new apps
            else:
                final_list = ["No new apps!!!!"]
        else:
            final_list = new_apps
    final_list = format_text(final_list, FONT)

    final_frame = render.Column(
        children = [
            render.Text("New apps:", font = "CG-pixel-3x5-mono"),
            render.Box(width = 64, height = 1, color = "#c993d5"),
            render.Marquee(
                height = 26,
                scroll_direction = "vertical",
                offset_start = 32,
                offset_end = 32,
                child = render.Column(
                    main_align = "space_between",
                    children = final_list,
                ),
            ),
        ],
    )
    return render.Root(
        delay = 100,  #speed up scroll text
        show_full_animation = True,
        child = final_frame,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "apps_only",
                name = "New apps only?",
                desc = "Enable to show only when there are new apps.",
                icon = "eyeSlash",
                default = True,
            ),
        ],
    )

######################################################
#functions
def get_apps():
    #get the data
    rep = http.get(BASE_URL)
    if rep.status_code != 200:
        return None
    else:
        data = [(x["id"], x["name"]) for x in rep.json()["apps"]]
    return dict(data)

def format_text(x, font):
    #formats color and font of text
    text_vec = []
    for i, word in enumerate(x):
        if i % 2 == 0:
            ctmp = "#c8c8fa"
        else:
            ctmp = "#fff"

        word_tmp = split_sentence(word, 14, join_word = True)  #combine and split words correctly
        text_vec.append(render.WrappedText(word_tmp, font = font, color = ctmp))
    return (text_vec)

def split_sentence(sentence, span, **kwargs):
    #split long sentences along with long words

    sentence_new = ""
    for word in sentence.split(" "):
        if len(word) >= span:
            sentence_new += split_word(word, span, **kwargs) + " "

        else:
            sentence_new += word + " "

    return sentence_new

def split_word(word, span, join_word = False):
    #split long words

    word_split = []

    for i in range(0, len(word), span):
        word_split.append(word[i:i + span])
    if join_word:
        return " ".join(word_split)
    else:
        return word_split
