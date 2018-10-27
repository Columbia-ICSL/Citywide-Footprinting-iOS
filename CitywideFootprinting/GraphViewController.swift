//
//  GraphViewController.swift
//  CitywideFootprinting
//
//  Created by Peter Wei on 10/27/18.
//  Copyright © 2018 Columbia ICSL. All rights reserved.
//
extension UIColor {
    @objc convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    @objc convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

import UIKit
import MapKit
import Charts

class myValueFormatter: NSObject, IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return "\(value) W"
    }
}

class timeValueFormatter: NSObject, IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = NSDate()
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date as Date)
        var hour = components.hour
        var minute = components.minute
        if ((6 - Int(value)) % 6 != 0) {
            return ""
        } else {
            let num = (13-Int(value))/6
            if (num > minute!) {
                hour = hour! - 1
            }
            minute = (minute!-num + 60) % 60
            var minString = ""
            if (minute! < 10) {
                minString = "0\(minute!)"
            } else {
                minString = "\(minute!)"
            }
            return "\(hour!):" + minString
        }
    }
}
class GraphViewController: UIViewController,ChartViewDelegate {

    @IBOutlet weak var EnergyChart: LineChartView!
    @IBOutlet weak var mapView: MKMapView!
    @objc let appBlack = UIColor(red:0x21, green:0x21, blue:0x21)
    @objc var reset = false
    @objc var vals = [5]
    @objc let color1 = UIColor(red:0xD6, green:0x68, blue:0x53)
    @objc let appGrey = UIColor(red:0x79, green:0x7B, blue:0x84)
    override func viewDidLoad() {
        super.viewDidLoad()
        let initialLocation = CLLocation(latitude: 40.810235, longitude: -73.961962)
        centerMapOnLocation(location: initialLocation)
        let artwork = Artwork(title: "Current Location",
                              locationName: "Northwest Corner Building",
                              discipline: "Location",
                              coordinate: CLLocationCoordinate2D(latitude: 40.810235, longitude: -73.961962))
        
        vals = [5, 10, 5, 255, 258, 270, 265, 530, 542, 510, 533, 534, 550, 545]
        
        mapView.addAnnotation(artwork)
        self.lineChartSetup()
        self.makeChart()
        
    }
    
    let regionRadius: CLLocationDistance = 500
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    @objc func lineChartSetup() {
        self.EnergyChart.delegate = self
        self.EnergyChart.noDataText = "Loading Data..."
        self.EnergyChart.noDataTextColor = appBlack
        self.EnergyChart.chartDescription?.text = "Tap to view"
        self.EnergyChart.chartDescription?.textColor = appBlack
        self.EnergyChart.gridBackgroundColor = UIColor.clear
        self.EnergyChart.xAxis.labelTextColor = appBlack
        self.EnergyChart.leftAxis.labelTextColor = appBlack
        self.EnergyChart.rightAxis.labelTextColor = appBlack
        self.EnergyChart.xAxis.labelPosition = XAxis.LabelPosition.bottom
        self.EnergyChart.backgroundColor = UIColor.clear
        self.EnergyChart.doubleTapToZoomEnabled = false
        self.EnergyChart.pinchZoomEnabled = false
        self.EnergyChart.rightAxis.drawGridLinesEnabled = false
        self.EnergyChart.rightAxis.drawAxisLineEnabled = false
        self.EnergyChart.leftAxis.drawAxisLineEnabled = false
        self.EnergyChart.drawBordersEnabled = false
        self.EnergyChart.xAxis.drawAxisLineEnabled = false
        self.EnergyChart.xAxis.drawGridLinesEnabled = false
        self.EnergyChart.rightAxis.drawLabelsEnabled = false
        self.EnergyChart.extraRightOffset = 10.0
        self.EnergyChart.dragEnabled = false
        self.EnergyChart.legend.enabled = false
        self.EnergyChart.leftAxis.axisMinimum = 0.0
        self.EnergyChart.leftAxis.valueFormatter = myValueFormatter()
        self.EnergyChart.xAxis.valueFormatter = timeValueFormatter()
        self.EnergyChart.drawMarkers = true
        self.EnergyChart.xAxis.setLabelCount(13, force: true)
    }
    
    @objc func makeChart() {
        if (reset == false) {
            reset = true
            setChartData()
        } else {
            updateCounter()
        }
    }
    
    @objc func setChartData() {
        var EnergyVals: [ChartDataEntry] = [ChartDataEntry]()
        for i in 0...(vals.count-1) {
            EnergyVals.append(ChartDataEntry(x: Double(i), y: Double(vals[i])))
        }
        let set1: LineChartDataSet = LineChartDataSet(values: EnergyVals, label: "HVAC Set")
        
        
        set1.fill = Fill(color: color1)
        set1.drawFilledEnabled = true
        set1.drawValuesEnabled = false
        
        
        set1.setColor(color1)
        set1.setCircleColor(appGrey)
        set1.lineWidth = 2.0
        set1.circleRadius = 3.0
        set1.fillAlpha = 150/255.0
        set1.highlightColor = appGrey
        set1.drawCircleHoleEnabled = true
        
        var dataSets: [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(set1)
        let data:LineChartData = LineChartData(dataSets: dataSets)
        data.setValueTextColor(appGrey)
        self.EnergyChart.data = data
        self.EnergyChart.data?.notifyDataChanged()
        let start = max(0, vals.count-13)
        self.EnergyChart.moveViewToX(Double(start))
        self.EnergyChart.setVisibleXRange(minXRange: Double(12.0), maxXRange: Double(12.0))
    }
    
    
    //Called every time to add a new (HVAC, light, electric) data point
    @objc func updateCounter() {
        let i = vals.count-1
        self.EnergyChart.data?.addEntry(ChartDataEntry(x:Double(i), y: Double(vals[i])), dataSetIndex: 0)
        let _ = self.EnergyChart.data?.removeEntry(xValue: Double(i-13), dataSetIndex: 0)
        self.EnergyChart.data?.notifyDataChanged()
        self.EnergyChart.notifyDataSetChanged()
        let start = i
        self.EnergyChart.moveViewToAnimated(xValue: Double(start), yValue: Double(vals[i]), axis: YAxis.AxisDependency.left, duration: 0.8, easingOption: ChartEasingOption.easeInSine)
        self.EnergyChart.setVisibleXRange(minXRange: Double(12.0), maxXRange: Double(12.0))
    }
}
