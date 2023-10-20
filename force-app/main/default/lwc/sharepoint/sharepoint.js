import { LightningElement, track, wire, api } from 'lwc';
import makeRequest from '@salesforce/apex/FileConnectController.makeRequest';
import FilesList from '@salesforce/apex/FileConnectController.FilesList';
import getFolderId from '@salesforce/apex/FileConnectController.getFolderId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAuthenticationData from '@salesforce/apex/FileConnectController.getSPAuthenticationData';
export default class UploadFile extends LightningElement {

  filteredFiles = [];
  next = true;
  prev = false;
  prevDots = false;
  nextDots = false;
  onetimeRender = true;
  pagesToIterate = [];
  nomberPages;
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
  @api recordId
  splitUrlarray = [];
  FolderUniqueId = '';
  selectedFiles = [];
  previewUrl;
  iframeSrc;
  columns = [
    { label: 'File Name', fieldName: 'name' },
    {
      label: 'Preview',
      type: 'button',
      initialWidth: 100,
      typeAttributes: {
        label: 'Preview',
        name: 'preview',
        title: 'Click to Preview',
        disabled: false,
        value: 'preview',
        variant: 'base',
      },
    },
  ];

  connectedCallback() {
    this.showSpinner = true;
    getAuthenticationData({})
      .then(result => {
        if (result) {
          let metadataRecs = JSON.parse(JSON.stringify(result));
          metadataRecs && metadataRecs.forEach(rec => {
            (rec["DeveloperName"] === 'sharepoint') && (this.splink = rec["Dx_File__Value__c"]);
            (rec["DeveloperName"] === 'downloadurl') && (this.downloadurl = rec["Dx_File__Value__c"]);
            (rec["DeveloperName"] === 'lwcendpoint') && (this.lwcendpoint = rec["Dx_File__Value__c"]);
          });
        }
      }).catch(error => {
        console.error('error---', error);
      });

    function formatBytes(bytes, decimals = 2) {
      if (!+bytes) return '0 Bytes'
      const k = 1024
      const dm = decimals < 0 ? 0 : decimals
      const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`
    }

    getFolderId({ recordId: this.recordId })
      .then(sharedFolderId => {
        this.FolderUniqueId = sharedFolderId;
        FilesList({ sharefolderIds: this.FolderUniqueId, searchContent: this.searchText })
          .then(data => {
            this.showSpinner = false;
            let companyName = '';
            this.fileData = [];
            this.filterData = [];
            for (const key of Object.keys(data)) {
              const filedata = data[key];
              // const urls = data[key].split(',');
              this.fileData.push({
                name: key,
                deleteUrl: filedata['deleteLink'],
                previewUrl: filedata['downloadLink'],
                createdDate: filedata['createdTime'],
                length: formatBytes(filedata['length'])
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

    makeRequest()
      .then(res => {
        this.accesstoken = res;
      })
      .catch(error => {
        console.error('error---', error);
      })
  }

  renderedCallback() {
    if (this.onetimeRender) {
      this.template.querySelectorAll('.page').forEach(element => {
        if (element.innerText == '1') {
          element.classList = 'page activePage';
        }
      });
    }
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

  get downloadLink() {
    let fileUrl = '/_layouts/15/download.aspx?sourceurl=/sites/LeadInfo/Leads/Account/Lightning Web Components Specialist Superbadge-0012w00000c4RlCAAU/priyankag@dextara.com-0052w000001sECZAA2/20230710T054723_GoogleFormAPIDetails.pdf';
    return `https://dextara.sharepoint.com/servlet/servlet.FileDownload?file=${encodeURIComponent(fileUrl)}`;
  }

  handlePreview(event) {
    const fileName = event.target.dataset.fileName; // The name of the file to download
    const fileDownloadUrl = event.target.dataset.url;
    let fileId = fileDownloadUrl.replaceAll(' ', '%20');
    const fileUrl = this.lwcendpoint + '_api/Web/GetFileByServerRelativeUrl(\'' + fileId + '\')//OpenBinaryStream()';
    fetch(fileUrl, {
      method: 'GET',
      headers: {
        'Authorization': 'Bearer ' + this.accesstoken,
        'Content-Type': 'application/json;odata=verbose',
      },
    })
      .then(response =>
        response.blob())
      .then(blob => {
        const blobUrl = URL.createObjectURL(blob);
        //alert(blob);
        alert(blobUrl);
        this.iframeSrc = blobUrl;
        // window.open(blob);
      })
      .catch(error => {
        console.error('Error fetching file content:', error);
      });
  }

  handleDelete() {
    this.showSpinner = true;
    if (this.selectedFiles.length > 0) {
      this.selectedFiles.forEach((file) => {
        const deleteUrl = file.deleteUrl;
        const url = deleteUrl
        const headers = {
          'Authorization': 'Bearer ' + this.accesstoken
        };

        fetch(url, {
          method: 'DELETE',
          headers: headers
        })
          .then(response => {
            if (!response.ok) {
              throw new Error(`HTTP error! Status: ${response.status}`);
            }
            this.showToast('success', 'File Deleted successfully: ');
            this.showSpinner = false;
            this.fileData = [];
            this.filterData = [];
            this.connectedCallback();
          })
          .catch(error => {
            console.error('Error:', error);
          });

      });
    }
  }

  handleDownload(event) {
    const fileName = event.target.dataset.fileName; // The name of the file to download
    const fileDownloadUrl = event.target.dataset.url;
    let fileId = fileDownloadUrl.replaceAll(' ', '%20');
    const fileUrl = this.lwcendpoint + '_api/Web/GetFileByServerRelativeUrl(\'' + fileId + '\')/OpenBinaryStream()';
    // Make an HTTP GET request to download the file
    fetch(fileUrl, {
      method: 'GET',
      headers: {
        'Authorization': 'Bearer ' + this.accesstoken,
        'Content-Type': 'application/json;odata=verbose'
      },
    })
      .then(response => {
        if (response.ok) {
          return response.blob(); // Convert the response to a Blob
        } else {
          throw new Error('Failed to download file');
        }
      })
      .then(blob => {
        // Create a temporary anchor element to trigger the download
        const downloadLink = document.createElement('a');
        const url = window.URL.createObjectURL(blob);
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
  }

  filedata2 = [];
  handleFileChange(event) {
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
    const endpointUrl = this.lwcendpoint + '_api/Web/GetFolderById(\'' + this.FolderUniqueId[1] + '\')/Files/add(url=\'' + file.name + '\',overwrite=true)';
    const headers = {
      'Authorization': 'Bearer ' + this.accesstoken,
    };
    this.showSpinner = true;
    const reader = new FileReader();
    reader.onloadend = () => {
      const fileContent = reader.result.split(',')[1];
      const byteCharacters = atob(fileContent);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: file.type });
      fetch(endpointUrl, {
        method: 'POST',
        headers: headers,
        body: blob
      })
        .then(response => {
          if (response.ok) {
            this.showToast('success', 'File uploaded successfully: ' + file.name);
            this.fileData.push(file);
            this.fileData = [];
            this.filterData = [];
            this.connectedCallback();
          } else {
            console.error('File upload failed:', file.name);
            this.showToast('error', 'File upload failed: ' + file.name);
          }
          this.showSpinner = false;
        })
        .catch(error => {
          console.error('Error uploading file:', error);
        });
    };
    reader.readAsDataURL(file);
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
      if (file.name.toLowerCase().includes(event.target.value.toLowerCase())) {
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