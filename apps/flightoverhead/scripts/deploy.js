// node scripts/deploy.js dotenv_config_path=scripts/.env

import axios from 'axios'
import axios_throttle from 'axios-request-throttle'
import fs from 'fs'
import * as child from 'child_process'
import 'dotenv/config'

const axios_config = {
	headers: { Authorization: `Bearer ${process.env.TIDBYT_API_TOKEN}` }
}

axios_throttle.use(axios, { requestsPerSecond: process.env.AIRLABS_TTL_SECONDS })

const AIRLABS_API_KEY = process.env.AIRLABS_API_KEY
const AIRLABS_BBOX = process.env.AIRLABS_BBOX
const AIRLABS_TTL_SECONDS = process.env.AIRLABS_TTL_SECONDS
const BACKGROUND = (String(process.env.TIDBYT_BACKGROUND).toLowerCase() === 'true')
const DISABLE_END_HOUR = process.env.DISABLE_END_HOUR
const DISABLE_START_HOUR = process.env.DISABLE_START_HOUR
const PRINT_LOG = (String(process.env.PRINT_LOG).toLowerCase() === 'true')
const RETURN_EMPTY_MESSAGE = process.env.RETURN_EMPTY_MESSAGE
const TIDBYT_APP_NAME = process.env.TIDBYT_APP_NAME
const TIDBYT_DEVICE_ID = process.env.TIDBYT_DEVICE_ID
const TIDBYT_INSTALLATION_ID = process.env.TIDBYT_INSTALLATION_ID
const TIMEZONE = process.env.TIMEZONE

let previous_hash = ''

const push = () => {

	let render_pixlet = child.spawn('pixlet', ['render', `${TIDBYT_APP_NAME}.star`, `airlabs_api_key=${AIRLABS_API_KEY}`, `airlabs_bbox=${AIRLABS_BBOX}`, `airlabs_ttl_seconds=${AIRLABS_TTL_SECONDS}`, `timezone=${TIMEZONE}`, `disable_start_hour=${DISABLE_START_HOUR}`, `disable_end_hour=${DISABLE_END_HOUR}`, `return_empty_message=${RETURN_EMPTY_MESSAGE}`, `print_log=${PRINT_LOG}`])

	render_pixlet.stdout.setEncoding('utf8')
	render_pixlet.stdout.on('data', (data) => {
		if (PRINT_LOG) console.log(data)
	})

	render_pixlet.on('close', (code) => {

		const webp = `./${TIDBYT_APP_NAME}.webp`

		fs.readFile(webp, 'base64', (error, data) => {

			if (error) {
				console.error(error)
				return
			}

			if (data !== previous_hash) {
				previous_hash = data

				axios
					.post(
						`https://api.tidbyt.com/v0/devices/${TIDBYT_DEVICE_ID}/push`,
						{
							"image": data,
							"installationID": TIDBYT_INSTALLATION_ID,
							"background": BACKGROUND
						},
						axios_config
					)
					.then((response) => {})
					.catch((error) => {
						console.error(error)
					})
			} else {}

		})

	})

}

const push_interval = setInterval(() => {
	push()
}, AIRLABS_TTL_SECONDS * 1000)

push()
