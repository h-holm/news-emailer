# News Emailer

A script using [Mutt](http://www.mutt.org) to programmatically send files as email attachments. The repo was created for scheduling the sending of scraped news EPUBs created by the [h-holm/raspberry-pi-news-fetcher](https://github.com/h-holm/raspberry-pi-news-fetcher) repo.

## Requirements

- The [`mutt`](http://www.mutt.org) command-line utility, configured to allow sending emails.

See [this "mutt-setup" gist](https://gist.github.com/h-holm/b023df59207926511f4399d6342d87c0) for guidance on setting up Mutt.

Make the script executable:

```shell
chmod u+x send_news_over_email.sh
```

## Sending Emails Programmatically

Run the [send_news_over_email.sh](./send_news_over_email.sh) script with the `--help` flag for details on how to use the script:

```shell
./send_news_over_email.sh --help
```

The script can be scheduled as a cron job.
