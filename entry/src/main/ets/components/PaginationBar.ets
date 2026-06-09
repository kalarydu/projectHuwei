@Component
export struct PaginationBar {
  @Prop current: number = 1;
  @Prop total: number = 1;
  onPageChange: (page: number) => void = () => {};

  build() {
    Row() {
      if (this.total <= 1) {
        Text('共 1 页')
          .fontSize(13)
          .fontColor('#999')
      } else {
        Button('上一页')
          .fontSize(13)
          .enabled(this.current > 1)
          .onClick(() => { if (this.current > 1) this.onPageChange(this.current - 1); })

        ForEach(this.getPageNumbers(), (p: number) => {
          Button(`${p}`)
            .fontSize(13)
            .backgroundColor(p === this.current ? '#1890ff' : '#fff')
            .fontColor(p === this.current ? '#fff' : '#333')
            .onClick(() => { if (p !== this.current) this.onPageChange(p); })
        })

        Button('下一页')
          .fontSize(13)
          .enabled(this.current < this.total)
          .onClick(() => { if (this.current < this.total) this.onPageChange(this.current + 1); })

        Text(`共 ${this.total} 页`)
          .fontSize(13)
          .fontColor('#999')
      }
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .padding({ top: 12 })
  }

  getPageNumbers(): number[] {
    const pages: number[] = [];
    const start = Math.max(1, this.current - 2);
    const end = Math.min(this.total, this.current + 2);
    for (let i = start; i <= end; i++) {
      pages.push(i);
    }
    return pages;
  }
}
