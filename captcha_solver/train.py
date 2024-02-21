import tensorflow as tf
try: [tf.config.experimental.set_memory_growth(gpu, True) for gpu in tf.config.experimental.list_physical_devices("GPU")]
except: pass

from keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau, TensorBoard

from mltu.tensorflow.dataProvider import DataProvider
from mltu.tensorflow.losses import CTCloss
from mltu.tensorflow.callbacks import Model2onnx, TrainLogger
from mltu.tensorflow.metrics import CWERMetric

from mltu.preprocessors import ImageReader
from mltu.transformers import ImageResizer, LabelIndexer, LabelPadding
from mltu.augmentors import RandomRotate, RandomErodeDilate
from mltu.annotations.images import CVImage
from mltu.configs import BaseModelConfigs

from model import train_model

import os


class ModelConfigs(BaseModelConfigs):
    def __init__(self):
        super().__init__()
        self.model_path = "models/"
        self.vocab = None # assigned later
        self.height = 44 # 50
        self.width = 140
        self.max_text_length = 0
        self.batch_size = 64
        self.learning_rate = 1e-3
        self.train_epochs = 1000
        self.train_workers = 20
        self.split_data_ratio = 0.9
    

# Create a list of all the images and labels in the dataset

def init():
    dataset = []
    vocab = set()
    max_len = 0
    captcha_path = "temp/captchas/"
    for file in os.listdir(captcha_path):
        file_path = os.path.join(captcha_path, file)
        label = os.path.splitext(file)[0] # Get the file name without the extension
        dataset.append([file_path, label])
        vocab.update(list(label))
        max_len = max(max_len, len(label))

    configs = ModelConfigs()

    # Save vocab and maximum text length to configs
    configs.vocab = "".join(vocab)
    configs.max_text_length = max_len
    configs.save()
    
    return (configs, dataset)

configs, dataset = init()

# Create a data provider for the dataset
data_provider = DataProvider(
    dataset=dataset,
    skip_validation=True,
    batch_size=configs.batch_size,
    data_preprocessors=[ImageReader(CVImage)],
    transformers=[
        ImageResizer(configs.width, configs.height),
        LabelIndexer(configs.vocab),
        LabelPadding(
            max_word_length=configs.max_text_length, 
            padding_value=len(configs.vocab))])

# Split the dataset into training and validation sets
train_data_provider, val_data_provider = data_provider.split(split = configs.split_data_ratio)

# Augment training data with random brightness, rotation and erode/dilate
train_data_provider.augmentors = [
    # RandomRotate(), 
    # RandomErodeDilate()
]

# Creating TensorFlow model architecture
model = train_model(
    input_dim = (configs.height, configs.width, 1),
    output_dim = len(configs.vocab))

# Compile the model and print summary
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=configs.learning_rate), 
    loss=CTCloss(), 
    metrics=[CWERMetric(padding_token=len(configs.vocab))],
    run_eagerly=False)

model.summary(line_length=110)
# Define path to save the model
os.makedirs(configs.model_path, exist_ok=True)

# Define callbacks
trainLogger = TrainLogger(configs.model_path)
earlystopper = EarlyStopping(monitor="val_CER", patience=50, verbose=1)
tb_callback = TensorBoard(f"{configs.model_path}/logs", update_freq=1)
model2onnx = Model2onnx(f"{configs.model_path}/model.h5")
checkpoint = ModelCheckpoint(
    f"{configs.model_path}/model.h5", 
    monitor="val_CER", 
    verbose=1, 
    save_best_only=True, 
    mode="min")
reduceLROnPlat = ReduceLROnPlateau(
    monitor="val_CER", 
    factor=configs.split_data_ratio, 
    min_delta=1e-10, 
    patience=20, 
    verbose=1, 
    mode="auto")

# Train the model
model.fit(
    train_data_provider,
    validation_data=val_data_provider,
    epochs=configs.train_epochs,
    callbacks=[earlystopper, checkpoint, trainLogger, reduceLROnPlat, tb_callback, model2onnx],
    workers=configs.train_workers)

# Save training and validation datasets as csv files
train_data_provider.to_csv(os.path.join(configs.model_path, "train.csv"))
val_data_provider.to_csv(os.path.join(configs.model_path, "val.csv"))