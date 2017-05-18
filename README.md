
# react-native-sm-imagepicker

## Getting started

`$ npm install react-native-sm-imagepicker --save`

### Mostly automatic installation

`$ react-native link react-native-sm-imagepicker`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-sm-imagepicker` and add `RNSmImagepicker.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNSmImagepicker.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.sm_imagepicker.RNSmImagepickerPackage;` to the imports at the top of the file
  - Add `new RNSmImagepickerPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-sm-imagepicker'
  	project(':react-native-sm-imagepicker').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-sm-imagepicker/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-sm-imagepicker')
  	```


## Usage
```javascript
import RNSmImagepicker from 'react-native-sm-imagepicker';

// TODO: What to do with the module?
RNSmImagepicker;
```
  