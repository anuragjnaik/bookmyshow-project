FROM nginx:alpine

WORKDIR /usr/share/nginx/html

RUN rm -rf ./*

COPY . .

CMD ["nginx", "-g", "daemon off;"]
