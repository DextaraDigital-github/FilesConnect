import { LightningElement, track, wire, api } from 'lwc';
import uploadFileToFolder from '@salesforce/apex/FileConnectController.uploadFileToFolder';
import downloadFile from '@salesforce/apex/FileConnectController.downloadFile';
import FilesList from '@salesforce/apex/FileConnectController.fileList';
import folderCreation from '@salesforce/apex/FileConnectController.folderCreation';
import deleteFile from '@salesforce/apex/FileConnectController.deleteFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class UploadFile extends LightningElement {

  filteredFiles = [];
  next = true;
  prev = false;
  prevDots = false;
  nextDots = false;
  onetimeRender = true;
  pagesToIterate = [];
  nomberPages; fileList
  @track fileData = [];
  @track searchData = [];
  @track filterData = [];
  @track isAllSelected = false;
  @track showSpinner = true;
  @track showData = true;
  @track refreshComponent = false;
  @track splink;
  @track downloadurl;
  @track lwcendpoint;
  @api recordId;
  splitUrlarray = [];
  FolderUniqueId = '';
  selectedFiles = [];
  previewUrl;
  iframeSrc;


  connectedCallback() {
    this.showSpinner = true;
    folderCreation({ recordId: this.recordId })
      .then(result => {
        this.FolderUniqueId = result;
        this.showSpinner = false;
        FilesList({ folderId: this.FolderUniqueId })//'1xhxulvJSvQbaoaXNVOb411mzHnCyuCZU'
          .then(data => {
            this.showSpinner = false;
            let companyName = '';
            this.fileData = [];
            this.filterData = [];
            for (const key of Object.keys(data)) {
              const filedata = data[key];
              this.fileData.push({
                name: key,
                id: filedata['id'],
                title: filedata['title'],
                createdDate: filedata['createdDate']
              });
            }
            this.searchData = this.fileData;
            for (let i = 0; i < 10; i++) {
              if (this.fileData[i] != null) {
                this.filterData.push(this.fileData[i]);
              }
            }
            this.numberOfPages = Math.ceil(this.searchData.length / 10);
            if (this.numberOfPages <= 3) {
              if (this.numberOfPages == 1) {
                this.pagesToIterate = [1];
                this.next = false;
                this.prev = false;
              }
              else if (this.numberOfPages == 2) {
                this.pagesToIterate = [1, 2];
              }
              else if (this.numberOfPages == 3) {
                this.pagesToIterate = [1, 2, 3];
              }
              this.nextDots = false;
              this.prevDots = false
            }
            else {
              this.pagesToIterate = [1, 2, 3];
              this.nextDots = true;
            }
          }).catch(error => {
            console.error('error---', error);
          })

      })
      .catch(error => {
        console.error(error);
      })

  }



  handleFileSelection(event) {
    const fileName = event.target.dataset.fileName;
    const isChecked = event.target.checked;
    if (isChecked) {
      const file = this.fileData.find((item) => item.name === fileName);
      if (file) {
        this.selectedFiles.push(file);
      }
    }
    else {
      const index = this.selectedFiles.findIndex((item) => item.name === fileName);
      if (index !== -1) {
        this.selectedFiles.splice(index, 1);
      }
    }
  }

  handleSelectAll(event) {
    this.isAllSelected = event.target.checked;
    this.fileData = this.fileData.map(file => {
      return {
        ...file,
        isChecked: this.isAllSelected
      };
    });
    if (this.isAllSelected) {
      this.selectedFiles = [...this.fileData];
    } else {
      this.selectedFiles = [];
    }
  }



  handleDelete(event) {
    this.showSpinner = true;
    if (this.selectedFiles.length > 0) {
      this.selectedFiles.forEach((file) => {
        const fileid = file.name;

        deleteFile({ fileId: fileid })
          .then(sharedFolderId => {

            this.showToast('success', 'File Deleted successfully: ');
            this.showSpinner = false;
            this.fileData = [];
            this.filterData = [];
            this.connectedCallback();
          })
          .catch(error => {
            console.error(error);
          })
      })
    }
  }


  handleDownload(event) {
    const fileName = event.target.dataset.value; // The name of the file to download
    const fileId = event.target.dataset.fileName;
    this.downloadFile(fileName, fileId);
  }

  downloadFile(fileName, fileId) {
    try {
      downloadFile({ fileId: fileId })
        .then(blob => {
          // Create a temporary anchor element to trigger the download
          const downloadLink = document.createElement('a');
          const url = window.URL.createObjectURL(new Blob([blob], { type: 'application/octet-stream' }));
          downloadLink.href = url;
          downloadLink.target = '_blank'; // Open in a new tab
          downloadLink.download = fileName; // Set the desired file name for download
          document.body.appendChild(downloadLink);
          downloadLink.click();
          window.URL.revokeObjectURL(url);
          document.body.removeChild(downloadLink);
        })
        .catch(error => {
          console.error(error);
          this.showToast('error', 'Failed to download file: ' + error.message);
        });
      
    } catch (error) {
      console.error('Error downloading file: ' + error);
    }
  }



  handleFileChange(event) {
    this.showSpinner = true;
    const files = event.target.files;
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const fileSizeInMB = file.size / (1024 * 1024);
      if (fileSizeInMB >= 10) {
        this.uploadFile(file);
        // this.showToast('error', 'file of size 10mb or larger cant be uploaded');
      }
      else {
        this.uploadFile(file);
      }
    }
  }


  uploadFile(file) {
    let folderid = this.FolderUniqueId;
    const reader = new FileReader();
    reader.onload = () => {
      uploadFileToFolder({ fileBlob: reader.result, folderId: folderid, fileName: file.name,fileType: file.type })
        .then(sharedFolderId => {
          this.showSpinner = false;
          this.connectedCallback();
          this.showToast('success', 'File uploaded successfully: ' + file.name);
        })
        .catch(error => {
          console.error(error);
        })
    };
    reader.readAsText(file);
  }



  showToast(status, messageToSend) {
    const event = new ShowToastEvent({
      title: messageToSend,
      variant: status
    });
    this.dispatchEvent(event);
  }

  handleUpload() {
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.style.display = 'none';
    fileInput.multiple = 'true';
    fileInput.onchange = this.handleFileChange.bind(this);
    document.body.appendChild(fileInput);
    fileInput.click();
    document.body.removeChild(fileInput);
  }

  handleSearch(event) {
    this.showData = false;
    this.searchData = [];
    this.filterData = [];
    let data = []
    this.fileData.forEach(file => {
      if (file.title.toLowerCase().includes(event.target.value.toLowerCase())) {
        this.searchData.push(file);
      }
    });
    this.numberOfPages = Math.ceil(this.searchData.length / 10);
    if (this.numberOfPages <= 3) {
      if (this.numberOfPages == 1) {
        this.pagesToIterate = [1];
        this.next = false;
        this.prev = false;
      }
      else if (this.numberOfPages == 2) {
        this.pagesToIterate = [1, 2];
      }
      else if (this.numberOfPages == 3) {
        this.pagesToIterate = [1, 2, 3];
      }
      this.prevDots = false;
      this.nextDots = false;
    }
    else {
      this.pagesToIterate = [1, 2, 3];
      this.nextDots = true;
    }
    let arr = [];
    // for (let i = 0; i < 10; i++) {
    //   if (this.searchData[i] != null) {
    //     data.push(this.searchData[i]);
    //   }
    // }
    this.searchData && this.searchData.forEach(srcdt => {
      if (srcdt != null) {
        data.push(srcdt);
      }
    })
    this.filterData = data;
    this.showData = true;
  }

  pageChange(event) {
    if (event.target.classList.contains('activePage')) {
    }
    else if (event.target.classList.contains('page')) {
      if (parseInt(event.target.innerText) == 1) {
        this.prev = false;
        this.next = true;
      }
      else if (parseInt(event.target.innerText) == 3) {
        this.prev = true;
        this.next = false;
      }
      else {
        this.prev = true;
        this.next = true;
      }
      this.filterData = [];
      for (let i = ((parseInt(event.target.innerText) - 1) * 10); i < parseInt(event.target.innerText) * 10; i++) {
        if (this.searchData[i] != null) {
          this.filterData.push(this.searchData[i]);
        }
      }
      this.template.querySelector('.activePage').classList = 'page';
      event.target.classList = 'page activePage';
    }
    else if (event.target.classList.contains('next')) {
      this.onetimeRender = false;
      let activePage = parseInt(this.template.querySelector('.activePage').innerText);

      this.template.querySelectorAll('.page').forEach(element => {
        if (element.innerText == activePage + 1) {

          element.click();
        }
      });

      if (activePage == this.numberOfPages - 1) {
        this.prev = true;
        this.next = false;
      }
      else if (activePage >= 2) {
        // for (let i = 0; i < this.pagesToIterate.length; i++) {
        //   this.pagesToIterate[i]++;
        // }
        this.pagesToIterate && this.pagesToIterate.forEach(pagelength => {
          pagelength = pagelength++;
        })
        this.prev = true;
        this.next = true;
        this.prevDots = true;
        if (activePage == this.numberOfPages - 2) {
          this.nextDots = false;
        }
      }
      else {
        this.prev = true;
        this.next = true;
      }

      this.template.querySelectorAll('.page').forEach(element => {
        if (element.innerText == activePage) {
          element.classList = 'page';
        }
        else if (element.innerText == activePage + 1) {
          element.classList = 'page activePage';
        }
      });

    }
    else if (event.target.classList.contains('prev')) {
      let activePage = parseInt(this.template.querySelector('.activePage').innerText);

      this.template.querySelectorAll('.page').forEach(element => {
        if (element.innerText == activePage - 1) {
          element.click();
        }
      });
      if (activePage == 2) {
        this.prev = false;
        this.next = true;
      }
      else if (activePage == this.numberOfPages) {
        this.prev = true;
        this.next = true;
      }
      else if (activePage > 2) {
        // for (let i = 0; i < this.pagesToIterate.length; i++) {
        //   this.pagesToIterate[i]--;
        // }
        this.pagesToIterate && this.pagesToIterate.forEach(pagelength => {
          pagelength = pagelength--;
        })
        this.prev = true;
        this.next = true;
        if (activePage == 3) {
          this.prevDots = false;
        }
        if (activePage == this.numberOfPages - 1) {
          this.nextDots = true;
        }
      }
      else {
        this.prev = true;
        this.next = true;
      }

      this.template.querySelectorAll('.page').forEach(element => {
        if (element.innerText == activePage) {
          element.classList = 'page';
        }
        else if (element.innerText == activePage - 1) {
          element.classList = 'page activePage';
        }
      });
    }
  }
}