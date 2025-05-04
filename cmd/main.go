package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

const (
	lang               = "en"
	wttrBaseURL        = "https://wttr.in/"
	wttrQueryParams    = "?format=4&lang="
	timeFormat         = "15:04:05"
	weatherLabelFormat = "Weather: %s"
	timeLabelFormat    = "Local Time: %s"
	windowSize         = 600
	unknownWeather     = "unknown"
)

func main() {
	a := app.New()
	w := a.NewWindow("Weather App")

	lbl := widget.NewLabel("Show weather for selected city!")
	lblWeather := widget.NewLabel(fmt.Sprintf(weatherLabelFormat, unknownWeather))
	lblTime := widget.NewLabel(fmt.Sprintf(timeLabelFormat, time.Now().UTC().Format(timeFormat)))

	input := widget.NewEntry()
	input.SetPlaceHolder("Enter city name for weather")
	cityName := ""
	button := widget.NewButton("Show Weather", func() {
		if input.Text != "" {
			cityName = input.Text
		}
		resp, err := http.Get(wttrBaseURL + cityName + wttrQueryParams + lang)
		if err != nil {
			log.Println(err)
		}
		defer resp.Body.Close()

		res := unknownWeather
		if resp.StatusCode == http.StatusOK {
			buf := make([]byte, 1024)
			n, err := resp.Body.Read(buf)
			if err != nil {
				log.Println(err)
			}
			res = string(buf[:n])
		}
		resp.Body.Close()
		lblWeather.SetText(fmt.Sprintf(weatherLabelFormat, res))
	})

	w.SetContent(
		container.NewVBox(
			lbl,
			lblWeather,
			input,
			button,
			lblTime,
		),
	)

	go func() {
		ticker := time.NewTicker(1 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			resp, err := http.Get(wttrBaseURL + cityName + wttrQueryParams + lang)
			if err != nil {
				log.Println(err)
				continue
			}

			res := unknownWeather
			if resp.StatusCode == http.StatusOK {
				buf := make([]byte, 1024)
				n, err := resp.Body.Read(buf)
				if err != nil {
					log.Println(err)
					continue
				}
				res = string(buf[:n])
			}
			resp.Body.Close()

			fyne.Do(func() {
				lblWeather.SetText(fmt.Sprintf(weatherLabelFormat, res))
			})
		}
	}()

	// Label updater
	go func() {
		labelTicker := time.NewTicker(1 * time.Second)
		defer labelTicker.Stop()
		for range labelTicker.C {
			fyne.Do(func() {
				lblTime.SetText(fmt.Sprintf(timeLabelFormat, time.Now().UTC().Format(timeFormat)))
			})
		}
	}()

	w.Resize(fyne.NewSize(windowSize, windowSize))
	w.ShowAndRun()
}
