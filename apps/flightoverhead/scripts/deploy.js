// node scripts/deploy.js dotenv_config_path=scripts/.env

import axios from 'axios'
import axios_throttle from 'axios-request-throttle'
import fs from 'fs'
import * as child from 'child_process'
import 'dotenv/config'

const axios_config = {
	headers: { Authorization: `Bearer ${process.env.TIDBYT_API_TOKEN}` }
}

axios_throttle.use(axios, { requestsPerSecond: process.env.PROVIDER_TTL_SECONDS })

const AIRLABS_API_KEY = process.env.AIRLABS_API_KEY
const BACKGROUND = (String(process.env.TIDBYT_BACKGROUND).toLowerCase() === 'true')
const DISABLE_END_HOUR = process.env.DISABLE_END_HOUR
const DISABLE_START_HOUR = process.env.DISABLE_START_HOUR
const IGNORE = process.env.IGNORE
const OPENSKY_USERNAME = process.env.OPENSKY_USERNAME
const OPENSKY_PASSWORD = process.env.OPENSKY_PASSWORD
const PRINT_LOG = (String(process.env.PRINT_LOG).toLowerCase() === 'true')
const PROVIDER = process.env.PROVIDER
const PROVIDER_BBOX = process.env.PROVIDER_BBOX
const PROVIDER_TTL_SECONDS = process.env.PROVIDER_TTL_SECONDS
const RETURN_MESSAGE_ON_EMPTY = process.env.RETURN_MESSAGE_ON_EMPTY
const SHOW_OPENSKY_ROUTE = process.env.SHOW_OPENSKY_ROUTE
const TIDBYT_APP_NAME = process.env.TIDBYT_APP_NAME
const TIDBYT_DEVICE_ID = process.env.TIDBYT_DEVICE_ID
const TIDBYT_INSTALLATION_ID = process.env.TIDBYT_INSTALLATION_ID
const TIMEZONE = process.env.TIMEZONE

let previous_hash = ''
let installation_exists = false;

const push = () => {

	let render_pixlet = child.spawn('pixlet', ['render', `${TIDBYT_APP_NAME}.star`, `provider=${PROVIDER}`,`airlabs_api_key=${AIRLABS_API_KEY}`, `opensky_username=${OPENSKY_USERNAME}`, `opensky_password=${OPENSKY_PASSWORD}`, `provider_bbox=${PROVIDER_BBOX}`, `provider_ttl_seconds=${PROVIDER_TTL_SECONDS}`, `timezone=${TIMEZONE}`, `disable_start_hour=${DISABLE_START_HOUR}`, `disable_end_hour=${DISABLE_END_HOUR}`, `return_message_on_empty=${RETURN_MESSAGE_ON_EMPTY}`, `ignore=${IGNORE}`, `show_opensky_route=${SHOW_OPENSKY_ROUTE}`, `print_log=${PRINT_LOG}`])

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

			const file_size = fs.statSync(webp)?.size

			if (data !== previous_hash) {
				previous_hash = data

				if (file_size) {
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
						.then((response) => {
							fs.unlink(webp, (error) => {
								if (error) console.error(error)
							})
						})
						.catch((error) => {
							console.error(error)
						})
				}

			}

			if (!file_size) {
				axios
					.get(
						`https://api.tidbyt.com/v0/devices/${TIDBYT_DEVICE_ID}/installations`,
						axios_config
					)
					.then((response) => {
						if (response.status == '200') {
							installation_exists = response.data.installations.some((installation => installation.id === TIDBYT_INSTALLATION_ID))
						}
					})
					.catch((error) => {
						console.error(error)
					})

				if (installation_exists) {
					axios
						.delete(
							`https://api.tidbyt.com/v0/devices/${TIDBYT_DEVICE_ID}/installations/${TIDBYT_INSTALLATION_ID}`,
							axios_config
						)
						.then((response) => {
							if (response.status == '200') {
								fs.unlink(webp, (error) => {
									if (error) console.error(error)
								})
								installation_exists = false;
							}
						})
						.catch((error) => {
							console.error(error)
						})
				}
			}

		})

	})

}

const push_interval = setInterval(() => {
	push()
}, PROVIDER_TTL_SECONDS * 1000)

push()
