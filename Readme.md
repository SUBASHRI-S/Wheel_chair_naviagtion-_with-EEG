# EEG-Based Wheelchair Navigation System
### Optimized Brain–Computer Interface for Assistive Mobility

[![MATLAB](https://img.shields.io/badge/MATLAB-Development-blue)](https://www.mathworks.com/products/matlab.html)
[![Machine Learning](https://img.shields.io/badge/AI-Machine%20Learning-purple)](#machine-learning-and-model-benchmarking)
[![BCI](https://img.shields.io/badge/Domain-Brain--Computer%20Interface-teal)](#system-architecture)
[![Hardware](https://img.shields.io/badge/Hardware-Arduino%20UNO-green)](#hardware-integration)

An EEG-driven wheelchair navigation prototype that combines non-invasive brain-signal acquisition, frequency-domain feature extraction, machine learning classification, and embedded motor control.

The system explores the translation of EEG activity acquired from the FP1 and FP2 forehead electrode positions into navigation commands. These commands are processed through a classification pipeline and communicated to an Arduino-based motor-control interface.

The engineering objective is to investigate a user-specific Brain–Computer Interface (BCI) architecture for assistive mobility.

---

## 1. Demonstration

**Project demonstration video**

[▶ Watch the EEG-Based Wheelchair Navigation Demonstration](https://drive.google.com/file/d/1fInispnyxtjJ1ahISD0H85R86Ug4wUGn/view?usp=sharing)

The video demonstrates the project's implemented workflow and hardware-oriented navigation functionality.

---

## 2. Engineering Overview

The system is divided into four functional layers:

| Layer | Engineering responsibility |
|---|---|
| Signal acquisition | Capture dual-channel EEG activity through FP1 and FP2 |
| Signal processing | Prepare EEG recordings and derive FFT-based spectral features |
| Intelligence | Train, compare, and use machine learning classifiers |
| Control execution | Convert predicted states into serial commands for Arduino-based motor control |

### Design objective

Develop a pipeline that can:

1. Acquire EEG signals without invasive procedures.
2. Build a labeled dataset of user-specific mental-state recordings.
3. Extract frequency-domain information from EEG signals.
4. Compare multiple machine learning architectures.
5. Classify navigation-related mental states.
6. Convert predictions into control commands.
7. Interface with an Arduino UNO and motor driver.

---

## System Architecture
![System architecture diagram](./image.png)

**Architecture overview:** The system separates neural-signal acquisition, feature engineering, machine-learning classification, command communication, and motor actuation into five functional layers. EEG-derived features are classified into movement intentions, translated into serial commands, and passed to the Arduino-based motor-control system.

**Movement command mapping:**

| Classified state | Serial command |
|---|---|
| Forward | `F` |
| Left | `L` |
| Right | `R` |
| Stop | `S` |
| Neutral | No movement command |

**Engineering principle:** Each layer has a distinct responsibility, allowing signal-processing algorithms, classification models, and hardware-control components to be evaluated and improved independently. Neutral or invalid predictions must not trigger movement.

## 4. EEG Data and Classification Classes

The project uses a custom EEG dataset representing navigation-related mental states.

EEG acquisition is described using a dual-channel configuration at the FP1 and FP2 forehead electrode positions.

### Classification categories

| Class | Intended user action |
|---|---|
| Forward | Concentration-based forward command |
| Left | Left-direction visual focus |
| Right | Right-direction visual focus |
| Stop | Voluntary jaw-clench trigger |
| Neutral | Resting or neutral mental state |

These are the intended mental-state mappings described in the project design.

**Dataset note:** The project source directory has four command folders (`forward`, `left`, `right`, `stop`), whereas the system design describes five classes, including Neutral. The Neutral data representation and handling should be confirmed against the actual dataset and MATLAB implementation.

---

## 5. Signal Processing and Feature Engineering

### FFT-based frequency analysis

The project uses Fast Fourier Transform (FFT) to transform EEG signals from the time domain into a frequency-domain representation.

The purpose is to extract spectral information that can be supplied to the machine learning classification stage.

### Processing sequence

```text
EEG Time-Series Data
        |
        v
Signal Preprocessing
        |
        v
Fast Fourier Transform
        |
        v
Frequency-Domain Representation
        |
        v
Spectral Feature Extraction
        |
        v
Feature Vectorization
        |
        v
Machine Learning Input
```

The project presentation identifies Alpha, Beta, and Theta frequency components as part of its EEG spectral-analysis approach.

### Feature representation

The extracted spectral information is formatted into structured feature vectors for model training and prediction.

The exact frequency bands, FFT configuration, feature dimensions, normalization method, and windowing parameters should be documented from the MATLAB implementation rather than assumed.

---

## 6. Machine Learning and Model Benchmarking

A comparative benchmarking strategy is used to evaluate six classification architectures.

### Evaluated models

| No. | Model | Classification approach |
|---:|---|---|
| 1 | Cubic SVM | Support Vector Machine |
| 2 | Random Forest | Tree-based ensemble |
| 3 | CNN | Convolutional Neural Network |
| 4 | PatternNet Neural Network | Neural-network classifier |
| 5 | XGBoost | Gradient-boosted decision trees |
| 6 | Bayesian-tuned Bagging Trees | Optimized bagging ensemble |

### Model benchmarking workflow

1. Prepare labeled EEG recordings.
2. Generate spectral feature representations.
3. Train the candidate classifiers.
4. Evaluate model predictions.
5. Compare classification performance.
6. Investigate optimization of selected models.
7. Integrate the chosen prediction approach into the command-generation workflow.

### Model selection reported in the project

The project presentation identifies:

- **XGBoost and Bayesian-tuned Bagging Trees** as high-performing models selected for further optimization.
- **PatternNet Neural Network** as the most accurate architecture in the proposed-system description.

These statements describe different parts of the presentation. A definitive model ranking requires the original model-comparison output and corresponding evaluation configuration.

---

## 7. Experimental Results

The project presentation reports a classification accuracy of **nearly 94%** in its conclusion.

It also contains precision-comparison analyses for four navigation commands:

- Left
- Right
- Forward
- Stop

### Reported evaluation summary

| Evaluation item | Project-reported result |
|---|---|
| Mental-state categories | 5 |
| Candidate ML architectures | 6 |
| Reported classification accuracy | Nearly 94% |
| Optimization focus | XGBoost and Bayesian-tuned Bagging Trees |
| Class-wise precision analysis | Left, Right, Forward and Stop |

**Interpretation:** The nearly 94% figure is reported in the project presentation. The exact model associated with that figure, test-set composition, validation methodology, and numerical class-wise precision values are not specified in the extracted presentation content.

For a reproducible evaluation, report the following when available:

| Metric | Purpose |
|---|---|
| Accuracy | Overall classification correctness |
| Precision | Correctness of predicted classes |
| Recall | Coverage of actual class samples |
| F1-score | Balance between precision and recall |
| Confusion matrix | Class-wise classification errors |
| Inference latency | Time required to generate a prediction |

Performance values should be populated from actual evaluation outputs, not estimated from presentation charts.

---

## 8. Command Generation and Communication

After classification, the predicted mental state is mapped to a serialized control command.

The hardware-actuation section of the project specifies the following command examples:

| Navigation command | Serial character |
|---|---|
| Forward | `F` |
| Left | `L` |
| Right | `R` |
| Stop | `S` |

The serialized command is transmitted through a communication interface to the Arduino controller.

Neutral-state behavior should be explicitly defined in the command logic. In particular, the system should not assume that Neutral automatically means Forward or that it is equivalent to Stop without implementation evidence.

### Control pipeline

```text
Predicted Class
      |
      v
Command Mapping
      |
      v
Serialized Character
      |
      v
Serial Communication
      |
      v
Arduino UNO
```

---

## 9. Hardware Integration

The project describes an Arduino-based motor-control architecture.

### Hardware components

| Component | Purpose |
|---|---|
| Neuroscience Basic Kit / Neurokit Basic | EEG acquisition |
| FP1 and FP2 electrodes | Dual-channel EEG input |
| Arduino UNO | Embedded command controller |
| L298N motor driver | Motor-driving interface |
| High-torque DC gear motors | Mechanical movement |
| Dual 18650 Li-ion cells | Listed 7.4 V power source |

### Motor-control architecture

The Arduino receives serialized commands and generates control signals for the L298N motor driver.

The driver interfaces with the DC gear motors to execute the corresponding movement operation.

### PWM control

Pulse Width Modulation (PWM) is used in the described motor-control design.

PWM regulates the average power delivered to a motor by adjusting the duty cycle of a switching signal.

The project architecture uses the following execution sequence:

1. Receive the control character.
2. Interpret the navigation command.
3. Generate the corresponding motor-control signals.
4. Interface with the L298N motor driver.
5. Execute the required motor operation.

The actual pin assignments, motor direction mapping, PWM duty-cycle values, and electrical wiring should be documented from the Arduino source code.

---

## 10. Software and Development Environment

The project presentation identifies the following development technologies:

| Category | Technology |
|---|---|
| Primary development | MATLAB |
| Additional programming environment | Python |
| EEG acquisition environment | ChordsAlpha |
| Embedded development | Arduino IDE |
| Code editor | Visual Studio Code |
| Operating system | Windows 10 / Windows 11 |
| Signal processing | FFT |
| Machine learning | SVM, Random Forest, CNN, Neural Network, XGBoost, Bagging Trees |

Required MATLAB toolboxes and Python packages should be determined from the actual source dependencies.

---

## 11. Repository Structure

The MATLAB project contains the following core files:

```text
eeg_wheelchair/
│
├── dataset/
│   ├── forward/
│   ├── left/
│   ├── right/
│   └── stop/
│
├── eeg_model.mat
│
├── evaluate_models.m
├── extract_features.m
├── load_dataset.m
├── main.m
├── predict_realtime.m
├── preprocess_signal.m
├── run_live_prediction.m
├── segment_and_preprocess.m
├── setup_dataset.m
├── test_arduino.m
├── train_models.m
│
├── README.md
├── CONTRIBUTING.md
└── .gitignore
```

### MATLAB module responsibilities

| File | Responsibility |
|---|---|
| `main.m` | Main project entry point |
| `setup_dataset.m` | Dataset preparation |
| `load_dataset.m` | EEG data loading |
| `preprocess_signal.m` | Signal preprocessing |
| `segment_and_preprocess.m` | Segmentation and preprocessing |
| `extract_features.m` | Feature extraction |
| `train_models.m` | Model training |
| `evaluate_models.m` | Model evaluation |
| `predict_realtime.m` | Prediction functionality |
| `run_live_prediction.m` | Live prediction workflow |
| `test_arduino.m` | Arduino communication testing |
| `eeg_model.mat` | Saved MATLAB model data |

---

## 12. Installation and Execution

### Prerequisites

- MATLAB.
- Required MATLAB toolboxes used by the project scripts.
- EEG dataset.
- Python and required packages, if used by the implementation.
- Arduino IDE for hardware development.
- Compatible EEG acquisition hardware for live operation.
- Arduino UNO, L298N, and DC motors for hardware experiments.

### Clone the repository

```bash
git clone https://github.com/SUBASHRI-S/Wheel_chair_naviagtion-_with-EEG.git
```

### Open the project

```bash
cd Wheel_chair_naviagtion-_with-EEG
```

Open the project directory in MATLAB and set it as the Current Folder.

### Execute the main script

```matlab
main
```

The repository also provides separate scripts for dataset preparation, signal processing, feature extraction, model training, evaluation, prediction, and Arduino communication testing.

**Execution requirements:** Confirm the script dependency order, required toolboxes, serial-port configuration, and live EEG acquisition settings from the implementation before running the complete system.

---

## 13. Reproducibility and Validation

Reliable model evaluation requires more than reporting overall accuracy.

For a stronger experimental workflow:

- Preserve the original EEG recordings.
- Maintain consistent class labels.
- Record the preprocessing configuration.
- Record the FFT and feature-extraction settings.
- Separate training and testing samples.
- Avoid leakage between training and evaluation data.
- Record model parameters and random seeds where applicable.
- Compare models using the same evaluation protocol.
- Report class-wise metrics alongside overall accuracy.
- Measure inference latency for real-time use.

For user-specific EEG datasets, evaluation across separate recording sessions can provide additional evidence of generalization.

---

## 14. Engineering Limitations

The current project design has several areas that require further investigation:

**Signal quality:** EEG recordings may contain noise, artifacts, and user-dependent variation.

**Class separation:** Similar signal patterns between mental states may affect classification reliability.

**Generalization:** A custom dataset may not represent the variation found across different users or recording sessions.

**Real-time performance:** Prediction accuracy alone does not establish acceptable end-to-end response time.

**Neutral-state handling:** The relationship between the five-class design and the four listed dataset folders requires clarification.

**Hardware reliability:** Communication failures, unexpected motor behavior, and incorrect commands require independent safeguards.

---

## 15. Future Engineering Improvements

Potential development directions include:

1. **Adaptive classification:** Investigate models that adapt to user-specific EEG changes.
2. **Improved signal quality:** Evaluate additional artifact-reduction and preprocessing techniques.
3. **Robust validation:** Test across independent sessions and users where appropriate.
4. **Latency optimization:** Measure and reduce end-to-end prediction and command delays.
5. **Environmental perception:** Investigate LiDAR or RGB-D sensing for obstacle awareness.
6. **Fault-tolerant control:** Add communication monitoring and safe-stop behavior.
7. **Safety architecture:** Introduce an independent emergency-stop mechanism.
8. **Usability evaluation:** Assess the system under an appropriately approved testing protocol.

---

## 16. Safety and Intended Use

This project is an educational and research-oriented assistive-technology prototype.

It is not a certified medical device or a clinically validated wheelchair-control system.

It must not be used as the sole control mechanism for an occupied wheelchair.

Any real-world deployment would require:

- Independent emergency-stop hardware.
- Safe behavior during signal loss and communication failure.
- Validation of command accuracy and response time.
- Controlled hardware testing.
- Appropriate engineering and safety assessments.
- Authorization and privacy protection for EEG data collection and distribution.
