recipe_dir := `pwd`

env:
  sed -e 's/^PORT=.*/PORT=8000/;\
    s/^MAX_MODEL_LEN=.*/MAX_MODEL_LEN=500000/;\
    s/^GPU_MEM_UTIL=.*/GPU_MEM_UTIL=0.84/;\
    s/^HEAD_IP=.*/HEAD_IP=192.168.177.11/;\
    s/^WORKER_IP=.*/WORKER_IP=192.168.177.12/;\
    s/^HEAD_CX7_IF=.*/HEAD_CX7_IF=enp1s0f1np1/;\
    s/^WORKER_CX7_IF=.*/WORKER_CX7_IF=enp1s0f1np1/;\
    s/^HEAD_CX7_IB=.*/HEAD_CX7_IB=rocep1s0f1/;\
    s/^WORKER_CX7_IB=.*/WORKER_CX7_IB=rocep1s0f1/;\
    s/^NCCL_IB_GID_INDEX=.*/NCCL_IB_GID_INDEX=2/;\
  ' .env.example > .env

update:
  git fetch origin
  if [ "$(git rev-parse main)" = "$(git rev-parse origin/main)" ]; then echo 'no update, exit.'; exit 0; fi
  git switch main
  git reset --hard origin/main
  git switch add_my_justfile
  git rebase main
  git push --force-with-lease hnakamur main add_my_justfile
  just env

update-justfile:
  git commit --amend --no-edit justfile
  git push --force-with-lease hnakamur add_my_justfile

quick-test:
  curl -s http://192.168.1.11:8000/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{"model": "GLM-5.3-Flash-EXL3", "messages": [{"role": "user", "content": "hello!"}]}'

restart:
  ssh pgx2 '\
    cd "{{recipe_dir}}" && \
    pwd && \
    git fetch origin && \
    git switch main && \
    git reset --hard origin/main \
  '
  rsync .env "pgx2:{{recipe_dir}}"

  ssh pgx1 '\
    cd "{{recipe_dir}}" && \
    git fetch origin && \
    git switch main && \
    git reset --hard origin/main \
  '
  rsync .env "pgx1:{{recipe_dir}}"
  ssh pgx1 '\
    cd "{{recipe_dir}}" && \
    ./stop.sh && \
    NCCL_HOST_DIR=/usr/lib/aarch64-linux-gnu WORKER_NCCL_HOST_DIR=/usr/lib/aarch64-linux-gnu ./start.sh \
  '
