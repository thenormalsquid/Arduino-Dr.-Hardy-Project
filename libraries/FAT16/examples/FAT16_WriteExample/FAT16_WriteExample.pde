/*
FAT16 WriteFile Example Sketch
SparkFun Electronics
Written by Ryan Owens
3/16/2010

Code Description: Uses an Arduino Duemillanove or Arduino Pro to write a string to a file.

Circuit Description: Uses the SparkFun microSD shield. (http://www.sparkfun.com/commerce/product_info.php?products_id=9520)

Attributions: Special thanks to Roland Riegel for providing an open source FAT library 
for AVR microcontrollers. See more of his projects here:
http://www.roland-riegel.de/

This code is provided under the Creative Commons Attribution License. More information can be found here:
http://creativecommons.org/licenses/by/3.0/

(Use our code freely! Please just remember to give us credit where it's due. Thanks!)
*/

//Add libraries to support FAT16 on the SD Card.
//(Note: If you already have these libraries installed in the directory, they'll have to remove in order to compile this.)
#include <byteordering.h>
#include <fat.h>
#include <fat_config.h>
#include <partition.h>
#include <partition_config.h>
#include <sd-reader_config.h>
#include <sd_raw.h>
#include <sd_raw_config.h>

//Define the pin numbers
#define CS    8
#define MOSI    11
#define MISO    12
#define SCK    13

//This is the amount of data to be fetched from the SD card for each read.
#define BUFFERSIZE	256

char buffer[BUFFERSIZE]="Testing\n";
char file_name[30];

struct fat_dir_struct* dd;		//FAT16 directory
struct fat_dir_entry_struct dir_entry;	//FAT16 directory entry (A.K.A. a file)

struct fat_fs_struct* fs;		//FAT16 File System
struct partition_struct* partition;	//FAT16 Partition

struct fat_file_struct * file_handle;	//FAT16 File Handle

void setup()
{
    //Set up the pins for the Serial communication
    pinMode(0, INPUT);
    pinMode(1, OUTPUT);
    Serial.begin(9600);
 
    //Set up the pins for the microSD shield
    pinMode(CS, OUTPUT);
    pinMode(MOSI, OUTPUT);
    pinMode(MISO, INPUT);
    pinMode(SCK, OUTPUT);
    pinMode(10, OUTPUT);
}

void loop()
{
  int bytes_read=0; //Keeps track of how many bytes are read when accessing a file on the SD card.
  int count=0;

  init_filesystem();	//Initialize the FAT16 file system on the SD card.
  
  //Create a file named Test.txt. If the file already exists, delete it and create a new one.
  if(!fat_create_file(dd, "Test.txt", &dir_entry)){
      fat_delete_file(fs, &dir_entry);
      fat_create_file(dd, "Test.txt", &dir_entry);
  }
  //Open the file that's just been created
  file_handle=open_file_in_dir(fs, dd, "Test.txt");
  //Write some initial data to the file
  fat_write_file(file_handle, (const uint8_t*)buffer, strlen(buffer));
  sd_raw_sync();    //An SD sync must be performed after each write operation
  fat_close_file(file_handle);    //Close the file.
  while(1){
      //Open the file (now we're at the beginning of the file again.
      open_file_in_dir(fs, dd, "Test.txt");
      //Read the contents of the file (up to 512 bytes)
      bytes_read = fat_read_file(file_handle, (uint8_t*)buffer, BUFFERSIZE);
      //Print the contents of the file
      Serial.println((const char*)buffer);
      //Now go to the end of the file to write some data.
      fat_seek_file(file_handle, 0, FAT_SEEK_END);
      sprintf(buffer, "%d", count++);
      //Write the new 'buffer' string to the end of the file
      fat_write_file(file_handle, (const uint8_t*)buffer, strlen(buffer));
      sd_raw_sync();
      //Close the file, we're finished!
      fat_close_file(file_handle);
      delay(1000);
  }
  
  while(1);
}

uint8_t find_file_in_dir(struct fat_fs_struct* fs, struct fat_dir_struct* dd, const char* name, struct fat_dir_entry_struct* dir_entry)
{
	fat_reset_dir(dd);	//Make sure to start from the beginning of the directory!
    while(fat_read_dir(dd, dir_entry))
    {
        if(strcmp(dir_entry->long_name, name) == 0)
        {
            //fat_reset_dir(dd);
            return 1;
        }
    }

    return 0;
}

struct fat_file_struct* open_file_in_dir(struct fat_fs_struct* fs, struct fat_dir_struct* dd, const char* name)
{
    struct fat_dir_entry_struct file_entry;
    if(!find_file_in_dir(fs, dd, name, &file_entry))
        return 0;

    return fat_open_file(fs, &file_entry);
}

char init_filesystem(void)
{
	//setup sd card slot 
	if(!sd_raw_init())
	{
		return 0;
	}

	//open first partition
	partition = partition_open(sd_raw_read,
									sd_raw_read_interval,
#if SD_RAW_WRITE_SUPPORT
									sd_raw_write,
									sd_raw_write_interval,
#else
									0,
									0,
#endif
									0
							   );

	if(!partition)
	{
		//If the partition did not open, assume the storage device
		//is a "superfloppy", i.e. has no MBR.
		partition = partition_open(sd_raw_read,
								   sd_raw_read_interval,
#if SD_RAW_WRITE_SUPPORT
								   sd_raw_write,
								   sd_raw_write_interval,
#else
								   0,
								   0,
#endif
								   -1
								  );
		if(!partition)
		{
			return 0;
		}
	}

	//Open file system
	fs = fat_open(partition);
	if(!fs)
	{
		return 0;
	}

	//Open root directory
	fat_get_dir_entry_of_path(fs, "/", &dir_entry);
	dd=fat_open_dir(fs, &dir_entry);
	
	if(!dd)
	{
		return 0;
	}
	return 1;
}

char get_next_filename(struct fat_dir_struct* cur_dir, char * new_file)
{
    //'dir_entry' is a global variable of type directory_entry_struct

    //Get the next file from the root directory
    if(fat_read_dir(cur_dir, &dir_entry))
    {
	sprintf(new_file, "%s", dir_entry.long_name);
        Serial.println((const char *)new_file);
        return 1;
    }
    //If another file isn't found, return 0
    return 0;
}


