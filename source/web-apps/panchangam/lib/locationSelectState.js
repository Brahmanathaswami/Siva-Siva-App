
import region_select from "./templates/region-select.hbs!";
import city_select from "./templates/city-select.hbs!";
import locationData from './location-data'
import calendarDisplayState from "./calendarDisplayState.js"




function bindCitySelector() {
    document.querySelectorAll("[data-ics]").forEach((item) => {
        item.addEventListener("click", function (el) {
            let url = item.getAttribute("data-ics");
            console.log("loading Panchangam from", url);
            document.querySelector("#city-selector").classList.add("hidden");
            document.querySelector("#city-loader").classList.remove("hidden");
            calendarDisplayState.makeActive(url);
        })
    })
}
function bindRegionSelector() {
    document.querySelectorAll(".region-selector").forEach(function (item) {
        item.addEventListener("click", function () {
            var region = item.getAttribute("data-region");
            showCitySelector(region);
        })
    })
}

function showRegionSelector() {
    document.querySelector("#today-display").innerHTML = region_select()
    bindRegionSelector()
}

function showCitySelector(region) {
    document.querySelector("#today-display").innerHTML = city_select(locationData[region])
    bindCitySelector()
}


let regionSelectState = {
    makeActive: function(region) {
        if (region) {
            showCitySelector(region)
        } else {
            showRegionSelector()
        }
    }
}

export default regionSelectState

//  file:///data/app/com.himalayanacademy.sivasiva-1/base.apk/assets/modules/panchangam/web/index.html